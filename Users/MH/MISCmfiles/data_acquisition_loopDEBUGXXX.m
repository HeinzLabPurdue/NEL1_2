function [block_info,stim_info] = data_acquisition_loop(DAL,nChannels,h_status,EP_nChannels)
global root_dir
global RP PA Trigger SwitchBox
global stm_common_parameters NelData

%%%%%
% This is done for efficiency only (because Matlab does not enable passing arguments by refference) - AF.
global spikes EPdata
%%%%%

%initialize
if (exist('nChannels','var') ~= 1)
   nChannels = 1;
end
if (exist('EP_nChannels','var') ~= 1)
   EP_nChannels = 1;
end
spikes.times = cell(1,nChannels);
spikes.last  = zeros(1,nChannels);
for i = 1:nChannels
   spikes.times{i} = zeros(100000,2);
end

if (isfield(DAL,'contPlotParams'))
   contPlotParams = DAL.contPlotParams;
else
   contPlotParams     = default_plot_raster_params(DAL.Gating.Period/1000);
end
if (isfield(DAL,'endLinePlotParams'))
   endLinePlotParams = DAL.endLinePlotParams;
else
   endLinePlotParams  = default_plot_rate_params(DAL.Gating.Period/1000,DAL.Gating.Duration/1000);
end
if (isfield(DAL,'endBlockPlotParams'))
   endBlockPlotParams = DAL.endBlockPlotParams;
else
   endBlockPlotParams = [];
end
if (isfield(DAL,'dispStatus'))
    dispStatus = DAL.dispStatus;
else
   dispStatus.func    = 'default_inloop_status';
   dispStatus.handle  = h_status;
end

rc = 1;
% common = stm_common_parameters;
common.index = 1;
common.dispStatus = dispStatus;  % To allow the inploopfunction to display status and errors.
common.short_description = DAL.short_description;
common.description = DAL.description;
msdl(1,nChannels);
%% Call Inloop function (loads/runs/sends appropriate params to the rcos)
[stim_info,block_info,plot_info] = call_user_func(DAL.Inloop.Name,common,DAL.Inloop.params);

%% EP acquisition init (loads the EP rco to the second RP if required)
if (isfield(NelData.General,'EP'))
   for i_ep = 1:EP_nChannels
      if (NelData.General.EP(i_ep).record == 1)
         [ep,rc] = EP_record(i_ep, NelData.General.EP(i_ep).duration, NelData.General.EP(i_ep).start); %% ADD i_ep in the future
         NelData.General.EP(i_ep).sampleInterval = 1000 / RP(2).sampling_rate;   % Equal to 1000msec/sampleFreq(Hz) for RP(2).
         NelData.General.EP(i_ep).lineLength = ...
            floor(NelData.General.EP(i_ep).duration / NelData.General.EP(i_ep).sampleInterval);
         NelData.General.EP(i_ep).lastN = 0;
         
         % some "short-hand" for use later:
         ep_lineLen = NelData.General.EP(i_ep).lineLength;
         ep_sampInt = NelData.General.EP(i_ep).sampleInterval;
         ep_lastN = NelData.General.EP(i_ep).lastN;
         
         EPdata(i_ep).X = (1:ep_lineLen) * ep_sampInt;   %in msec
         EPdata(i_ep).aveY = zeros(1, ep_lineLen);
         EPdata(i_ep).allY = repmat(NaN, block_info.nlines, ep_lineLen);  %% Pre-alloc more here??
         
         % plot initializations:
         NelData.General.EP(i_ep).plotFunc = 'default_plot_EP';
         call_user_func(NelData.General.EP(i_ep).plotFunc, i_ep);
      end
   end
end

%% Pulse stim init
if (isfield(NelData.General,'Pulse'))
   if (NelData.General.Pulse.enabled == 1)
      rc = Pulse_stim(NelData.General.Pulse.delay);
   end
end

%% Attens and SwitchBox code
stim_info.attens_devices = stim_info.attens_devices .* DAL.Mix;
if (~isstruct(stim_info))
   rc =0; 
else
   nlines  = block_info.nlines;
   MAXtrigs=2*nlines;  %% For RP pulse train
   MAX_pre_nlines=ceil(1.3*nlines);  %% For memory pre-allocation
   %% Pre-allocate space for all possible stim_info lines, but fill with NaN's and {'XXX'}'s
   stim_info(2:MAX_pre_nlines) = repmat(mark_stim_invalid(stim_info(1)), MAX_pre_nlines-1,1);
   [select,connect,PAattns] = find_mix_settings(stim_info(1).attens_devices); 
   if (isempty(select) | isempty(connect))
      nelerror('''data_acquisition_loop'': Can''t find appropriate select and connect parameters. Aborting...');
      return;
   end
   rc = SBset(select,connect) & (rc==1);
   rc = PAset(PAattns) & (rc==1);
   rc = (Trigcheck & (rc==1));
   if (rc)
      rc = TRIGset(DAL.Gating.Duration,DAL.Gating.Period,MAXtrigs) & (rc==1);
      trig_off_time = (DAL.Gating.Period - DAL.Gating.Duration) / 1000;
      trig_period   = DAL.Gating.Period / 1000;
      [rc_set,RP] = RPset_params(RP);
      rc = rc_set & (rc==1);
   end
end
if (rc ~= 1)
   nelerror('''data_acquisition_loop'': One or more errors detected. Aborting...');
   return;
end
%if (~isempty(contPlotParams))
contPlotParams = call_user_func(contPlotParams.func,[],contPlotParams,plot_info,nChannels);
%end
%if (~isempty(endLinePlotParams))
endLinePlotParams = call_user_func(endLinePlotParams.func,0,endLinePlotParams,plot_info,nChannels);
%end

%% PreLoop preparation or adaptation or whatever;
common.index = 0;
call_user_func(DAL.Inloop.Name,common,DAL.Inloop.params);
%%
NelData.run_mode = 1;
TRIGstart;
call_user_func(dispStatus.func,dispStatus.handle,1,plot_info);
max_spike_time = 1.0005 * DAL.Gating.Period/1000;
trig_state = 1;
number_of_presented_lines = 0;
number_of_presented_stims = 0;
end_of_loop_flag = 0;
index = 1;
%% Added for better state-detection and error checking (MGH & AF: 7/16/02)
last_stimsent_index=0; %%%  stimulus index at which the last stimulus was sent SUCCESSFULLY!
stimstat_index=1;  %% current stim being played: For plotting status 
Nbadstim=0;  %% counts # of bad lines
bad_lines=[];
line_errors={};
%%

%% For debugging
inloop_time_stamp = clock;%%X
PRINTyes=0; %%X
LATEerrlines=[3 7 23 26 29];
MISSerrlines=[12 16 18];
%LATEerrlines=-[3 7 23 26 29];
%MISSerrlines=[5];
%% 

%%%%%%%%%%% MAIN PRESENTATION LOOP %%%%%%%%%%%%%%%
%% SIMPLIFIED DETECTION AND ERROR CHECKING FOR STIM UPDATE and PLOTTING (MGH & AF 7/16/02)
%% to avoid not catching missed stimuli, and to reduce how often errors occur
%
% PLOTTING: if index>prev_index, ==>PLOT!
% STIM UPDATE: if index-Nbadstim>last_stimsent_index & TRIGstate=2, ==>UPDATE!! 

%% For debugging
loop_times = NaN*zeros(1,10000); loop_counter = 1;%%X
%%

while (end_of_loop_flag == 0)

   %% For debugging
   if sum(index==MISSerrlines)
      pause(trig_period)
   end
   if index==35
      pause(6*trig_period)
   end
   %%   
      
   %% For debugging
   inloop_elapsed_time = etime(clock,inloop_time_stamp);%%X
   loop_times(loop_counter) = etime(clock,inloop_time_stamp); loop_counter = loop_counter+1;%%X
   inloop_time_stamp = clock;  %%X
   %% 
   
   trig_prev_state = trig_state;
   prev_index      = index;  
   %%% SWITCHED ORDER (MH & AF: 7/16/02) (index before TRIGstate) TO SIMPLIFY detecting occurence of trigger downswing
   [spk index msdl_status] = msdl(2);
   [trig_state count_down] = TRIGget_state;
   
   %% For debugging
   %      PRINTyes=1;  % uncomment to see indices for every loop pass, o/w only on errors
   if(PRINTyes) %only print if error
      fprintf('Last_sentstim_index=%d; Nbad=%d; curstim=%d; Prev_index=%d; index=%d; prev trig_state=%d; trig_state=%d; loop_count=%d; elapsed_loop_time=%.3f\n', ...
         last_stimsent_index,Nbadstim,stimstat_index,prev_index,index,trig_prev_state,trig_state,loop_counter,loop_times(loop_counter-1)) %%X
      PRINTyes=0;
   end
   %%
   
   if (any(msdl_status) < 0)
      nelwarn(['msdl error (' int2str(msdl_status(msdl_status<0)) ') in line ' int2str(index)]);
   end
   % 7/31/02: MGH: added condition to index check to verify last stim not missed
   if ((trig_state == 0) & (count_down == MAXtrigs)) | ((index-Nbadstim>nlines) & (last_stimsent_index == nlines-1))
      %% End of picture: Either TDT counter ran out, or all stimuli were completed
      end_of_loop_flag = 1;
      if(trig_state==0) %% End of picture: TDT counter ran out
         index = index+1; % add 1 trigger, since RP pulses ran out
         nelerror(sprintf('Only %d of %d stimuli presented!! RP2 pulses ran out!', ...
            last_stimsent_index,nlines));
         stimstat_index=stimstat_index-1;
      end
   else
      %% Checks major discrepancies between TDT and counter board, e.g., trigger not connected
      if ((((MAXtrigs-count_down+1)-index < 0) | ((MAXtrigs-count_down+1) - index  >1)) & ~(MAXtrigs == index))
         nelerror(sprintf( ...
            'Inconsistent line number in RP2 (%d) and counter-card (%d). Check Trigger connections!', ...
            MAXtrigs-count_down+1, index));
      end     
   end

   %% CHECK for MISSED stimulus (1 or more)
   if ((index-last_stimsent_index-Nbadstim>1)&(~end_of_loop_flag)) 
      if (index-last_stimsent_index-Nbadstim==2)
         nelerror(sprintf('Stimulus %d was MISSED (line %d)!! ... repeated',last_stimsent_index+2,index));
      else
         nelerror(sprintf('Stimuli %d:%d were MISSED (lines %d:%d)!! ... repeated', ...
            last_stimsent_index+2,index-Nbadstim,last_stimsent_index+2+Nbadstim,index));
      end
      ding;
      if(~Nbadstim)
         nelerror('Reduce system/Matlab load; increase Gating period!!');  % Only show this on 1st bad stimulus
      end
      
      %% For debugging
      fprintf('Last_sentstim_index=%d; Nbad=%d; curstim=%d; Prev_index=%d; index=%d; prev trig_state=%d; trig_state=%d; loop_count=%d; elapsed_loop_time=%.3f\n', ...
         last_stimsent_index,Nbadstim,stimstat_index,prev_index,index,trig_prev_state,trig_state,loop_counter,loop_times(loop_counter-1)) %%X
      PRINTyes=1;
      fprintf('Stimuli %d:%d were MISSED (lines %d:%d)!!\n', ...
         last_stimsent_index+2,index-Nbadstim,last_stimsent_index+2+Nbadstim,index) %%X
      %%%
      
      %% Bookkeeping
      stimstat_index=last_stimsent_index+1;  %%%%% Show stimulus actually being presented (for status plot)
      
      %% Update stim_info to record stimuli actually presented
      stim_info(last_stimsent_index+2+Nbadstim:index)=repmat(stim_info(last_stimsent_index+1+Nbadstim), ...
         length(last_stimsent_index+2+Nbadstim:index),1);
      
      %% Update plotting values to deal with repeats: if bad lines, spikes not plotted
      contPlotParams.var_vals(index+1:end+length(last_stimsent_index+2+Nbadstim:index))= ...
         contPlotParams.var_vals(last_stimsent_index+2+Nbadstim:end);
      contPlotParams.var_vals(last_stimsent_index+2+Nbadstim:index)= ...  
         repmat(NaN,length(last_stimsent_index+2+Nbadstim:index),1);  % Don't plot unintended repeats     
      %%%%%%%%%%%%%
      %% TODO: Same thing for EndLinePlotParams
      %%%%%%%%%%%%%

      %% Record badlines and error types
      bad_lines=[bad_lines last_stimsent_index+2+Nbadstim:index];
      line_errors=[line_errors repmat({'miss'},1,length(last_stimsent_index+2+Nbadstim:index))];
      
      %% Last thing, is to update number of BAD stimulus lines
      Nbadstim=Nbadstim+length(last_stimsent_index+2+Nbadstim:index);    
   end
   
   % Check spikes. Trim longer than max_spike_time for the last line only.
   for i = 1:length(spk)
      if (any(spk{i}(:,2) < 0))
         nelerror('ERROR IN msdl: NEGATIVE spike times!!!');
      end
      if (index-Nbadstim>nlines)  % Remove spikes from any extra pulses after all stim presented
         bad_spikes = (spk{i}(:,1) > nlines+Nbadstim);
         spk{i} = spk{i}(~bad_spikes,:);
      end
      bad_spikes = (spk{i}(:,2) > max_spike_time);
      if (any(bad_spikes))
         if ((index-Nbadstim >= nlines) | (index>=MAXtrigs))  %% Take extra spikes away from last line 
            spk{i} = spk{i}(~bad_spikes,:);
         else
            nelerror('ERROR IN msdl: Spike times longer than stimulus period!!!');
         end
      end
   end
   
   %% Acquire EP 
   if (isfield(NelData.General,'EP'))
      for i_ep = 1:EP_nChannels
         if  (NelData.General.EP(i_ep).record == 1)
            [ep,rc] = EP_record(i_ep); %% ADD i_ep into EP_record in the future and implement below
            if (~isempty(ep))
               NelData.General.EP(i_ep).lastN = NelData.General.EP(i_ep).lastN + 1;
               ep_lastN = NelData.General.EP(i_ep).lastN;
               if (ep_lastN ~= index)
                  nelerror('IN data_acquisition_loop: spike line and EP acquisition indexing are not synchronized.');
               end
               EPdata(i_ep).aveY = ...
                  ( (EPdata(i_ep).aveY * (ep_lastN - 1)) + (ep{1}(1:ep_lineLen)) ) / ep_lastN;
               EPdata(i_ep).allY(ep_lastN,:) = ep{1}(1:ep_lineLen);
               call_user_func(NelData.General.EP(i_ep).plotFunc, i_ep, ...
                  EPdata(i_ep).X, EPdata(i_ep).aveY, ...
                  EPdata(i_ep).X, EPdata(i_ep).allY(ep_lastN, :));
            end
         end
      end
   end
   %% MH: ADD ERROR CHECKING HERE FOR EP RECORDING???
   %% MH: is order correct here? Should EP be done before plotting spikes? Does it matter?
   
   call_user_func(contPlotParams.func,spk,contPlotParams);
   concat_spikes(spk);
   drawnow
   
   if (check_stop_request), break; end  

   %% CHECK if ready to load new stimulus
   if ((index-Nbadstim>last_stimsent_index)&(trig_state == 2))  % Trigger pulse switched to off
      number_of_presented_stims = index;  % This stores total stim presented (good or bad)
      % Check again for user break before we prepare for the next stimulus
      if (check_stop_request), break; end
      
      %% For debugging
      if  sum(index==LATEerrlines)
         pause(.9*trig_off_time)
      end
      %%        

      %Prepare for next stimulus
      if (index-Nbadstim < nlines)
         common.index = last_stimsent_index+2;  %% Next stim to be sent
         [stim_info(index+1)] = call_user_func(DAL.Inloop.Name,common,DAL.Inloop.params);
         if (~isstruct(stim_info(index+1)))
            rc =0; break;
         end
         stim_info(index+1).attens_devices = stim_info(index+1).attens_devices .* DAL.Mix;
         [rc_set,RP] = RPset_params(RP);
         rc = rc_set & (rc==1);
         if (~all(nan_equal(stim_info(index+1).attens_devices,stim_info(index).attens_devices)))
            [select,connect,PAattns] = find_mix_settings(stim_info(index+1).attens_devices);
            rc = SBset(select,connect);
            rc = PAset(PAattns);
         end
         %%% Check that next trigger has not occurred before stimulus loaded!!!!
         index_increment=msdl(4);        
         if (index-Nbadstim+index_increment-last_stimsent_index>1)  % MAJOR PROBLEM: STIMULUS NOT LOADED IN TIME
            ding;
            nelerror(sprintf('Stimulus %d not loaded in time (line %d) ...repeated', ...
               last_stimsent_index+2,index+1));
            if(~Nbadstim)
               nelerror('Reduce system/Matlab load; increase Gating period!!');
            end

            %% For debugging
            fprintf('Last_sentstim_index=%d; Nbad=%d, curstim=%d; Prev_index=%d; index=%d; prev trig_state=%d; trig_state=%d; loop_count=%d; elapsed_loop_time=%.3f\n', ...
               last_stimsent_index,Nbadstim,stimstat_index,prev_index,index,trig_prev_state,trig_state,loop_counter,loop_times(loop_counter-1)) %%X
            PRINTyes=1;
            fprintf('Stimulus %d not loaded in time (line %d)!!! (index_increment=%d)\n',last_stimsent_index+2,index+1,index_increment)            
            %%
            
            %% Mark stiminfo(index+1)=INVALID, because we can't be sure it was completely loaded
            stim_info(index+1)=mark_stim_invalid(stim_info(index+1),'STIMULUS INVALID');
            
            %% Update plotting values to deal with repeats: if bad lines, spikes not plotted
            contPlotParams.var_vals(index+2:end+1)= ...
               contPlotParams.var_vals(index+1:end);
            contPlotParams.var_vals(index+1)=NaN;  % Don't plot unintended repeats
            %%%%%%%%%%%%%
            %% TODO: Same thing for EndLinePlotParams
            %%%%%%%%%%%%%
            
            %% Record badlines and error types
            bad_lines=[bad_lines index+1];
            line_errors=[line_errors {'late'}];
            
            %%%%% 
            stimstat_index=last_stimsent_index+2;  % Show stim that was loaded UNSUCCESSFULLY
            Nbadstim=Nbadstim+1;
         else
            last_stimsent_index=last_stimsent_index+1;  % Only count SUCCESSFULLY loaded stim 
            stimstat_index=last_stimsent_index+1;                
         end
      else
         % If last stim has finished (MH: 7/19/02), turn off sound to avoid hearing extra stimuli
         %% These values from: [select,connect,PAattns] = find_mix_settings(NaN*stim_info(1).attens_devices)
         %% But are hard-coded here to avoid 'find_mix_settings.m' warning that nothing will be heard
         rc = PAset(PAattns-PAattns+120);
         rc = SBset([7 7],[0 0]);
      end
   end
   
   % AF & MGH (7/16/02): added prev_index to simplify detection of new line
   %                     and changed the plot to work with prev_index instead of index-1.
   if (index>prev_index)  %% Simple detection for plotting, no matter if badstim
      % Trigger pulse switched to on or last line ended.
      number_of_presented_lines = prev_index;   % This stores total lines presented (good or bad)
      %% THIS IS A HUGE TIME SINK!! Loop delays grow linearly with # of spikes, eventually causing stim errors!!!!  
      %% MGH & GE: 7/22/02: Commented this out, so if fig minimized, old spikes in raster are gone
      %% But, refreshed at end of picture, so eventually they will come back!
      %      call_user_func(contPlotParams.func,{},contPlotParams,[],[],1:nChannels); % Allow contplot to set all the data points.
      call_user_func(endLinePlotParams.func,prev_index,endLinePlotParams);
      %% Match to stimulus actually being played
      call_user_func(dispStatus.func,dispStatus.handle,stimstat_index,plot_info);
   end
   if (rc ~= 1)
      break;
   end
end
if (~check_stop_request), beep; end % AF 06/11/02
RPhalt(RP);
RPclear(RP);
PAset(PAattns-PAattns+120);
SBset([7 7],[0 0]);
if (end_of_loop_flag)  
   %7/31/02: MGH: min(index-1,end) should never use end, but just in case to avoid losing data on error
   stim_info = stim_info(1:min(index-1,end));  %Remove extra pre-allocated lines
else  % user (or error) break, not all the stimuli were fully presented!
   stim_info = stim_info(1:min(index,end));  %Store all lines presented at all, good or bad
end
block_info.fully_presented_stimuli = number_of_presented_stims;
block_info.fully_presented_lines = number_of_presented_lines;
block_info.bad_lines=bad_lines;
block_info.line_errors=line_errors;
%% This refreshes the contPlot in case it was minimized during loop
call_user_func(contPlotParams.func,{},contPlotParams,[],[],1:nChannels); % Allow contplot to set all the data points.
%%%cleanup
call_user_func(DAL.Inloop.Name);
msdl(0);
SBset([],[]);
if (rc ~= 1)
   nelerror('''STM'': Error(s) detected within stimulus presentation loop');
end
%% For debugging
asdfasdfasdf = 1;   % For debugging breakpoint to look at loop_times
%%