function [tmplt,DAL,stimulus_vals,units,errstr] = TONE_reBFi_template(fieldname,stimulus_vals,units)
% MH 24Mar2005: for R03 project
% Modified from TEHrBFi to just do TONE, with slightly different params
% Modified version to allow interleaving with TONE, multi-levels, and hard-coded OCT-SHIFT list
% Also changed calibration 3/25/05 to be based on individual Target Frequencies, rather than on 1 BaseTarget Frequency
% From EH_reBFi_template
%
% MH 10Nov2004: for NOHR project
% Modified version to allow interleaving of conditions (
% From EH_reBF_template
%
% Initial creation LIMITATIONS:
%     1) limited to one Polarity
%     2) assumes 1 filename
%     3) probably limited somewhere to 1 level, if more than 1 ur??  THIS SHOULD BE FIXED EVENTUALLY
%
%
%    places features near BF for a BASELINE EH with F2 at BF and F0=75 Hz
%
% From EH_template (CNexps)
% Template for EH-vowel RLFs, using NI board to allow resampling
%
% MH 07Nov2003, modified from 'nel_NI_wavefile_template'
%
%  Written by GE, adapted from 'nel_wavefile_template' written by AF (11/26/01).
%  Modification dates: 03oct2003, 04oct2003.

% persistent   prev_playdur  prev_min_period  % GE debug: not really necessary???
% We use the persistent variables to detect a change that requires some fields update.
% For example, if the play duration is changed we would like to update the gating information.
% We restict the automatic updates to allow the user the overide them.

used_devices.File         = 'L3';    % ge debug: what if R3 is used also?
tmplt = template_definition(fieldname);
if (exist('stimulus_vals','var') == 1)

   %%% Make sure the needed BASELINE-EH wavfile exists.  If not, create it before proceeding
   %%%  BASELINE-EH has F2 at BaseFreq and F0=75Hz;
   %%%  wavfile is of 1 cycle of the vowel
   global signals_dir
   EHsignals_dir=strcat(signals_dir,'MH\EHvowels');

   % MH 17Nov2004
   % If no BF is defined, e.g., on startup, need to catch this before all the calcs get done
   if isempty(stimulus_vals.Inloop.BaseFrequency)
      stimulus_vals.Inloop.BaseFrequency=.01;  % Will get through, and let you change later
   end
   
   BASELINE_TargetFreq_Hz=stimulus_vals.Inloop.BaseFrequency*1000;
   % MH: 12Nov2004 - keeps basic shape the same for all BFs, meeting our constraints
   if BASELINE_TargetFreq_Hz>=500
      BASELINE_F0_Hz=75;  % BFs: >=500
   elseif (BASELINE_TargetFreq_Hz>=300)&(BASELINE_TargetFreq_Hz<500)
      BASELINE_F0_Hz=45;  % BFs:300-500
   elseif BASELINE_TargetFreq_Hz<300
      BASELINE_F0_Hz=15;  % BFs:100-300
   else
      BASELINE_F0_Hz=75;  % in case BASELINE_TargetFreq_Hz is empty or something, e.g, on startup
   end
   BASELINE_Feature='F2';
   Fix2Harms=strcmp(stimulus_vals.Inloop.FormsAtHarmonics,'yes'); % Set formants at nearest harmonic: 0:no, 1:yes
   PolarityFact=(strcmp(stimulus_vals.Inloop.InvertPolarity,'yes')-.5)*-2;  % For inverting waveform if necessary
   % Get filename and FormFreqs: mode 3 returns empty stim,Fs,dBreTONE
   [Xstim,XFs,filename,XdBreTONE,BASELINE_FormFreqs_Hz]= ...
      synth_BASELINE_eh(BASELINE_TargetFreq_Hz,BASELINE_F0_Hz,BASELINE_Feature,Fix2Harms,3);
   %%% MH: 11Nov2004 Check here for problems with stimulus design (e.g., formants at 0 freq, or equal to other formants 
   if length(unique(BASELINE_FormFreqs_Hz))~=length(BASELINE_FormFreqs_Hz)|sum(BASELINE_FormFreqs_Hz==0)
      BADstim=1;
   else
      BADstim=0;
   end

   stimulus_vals.Inloop.Compiled_FileName=fullfile(EHsignals_dir,filename);
   if ~BADstim   
      % If file does not exist, synthesize the new BASELINE vowel and save as a new wavfile
      if isempty(dir(fullfile(EHsignals_dir,filename)))
         % stim returned is 1 cycle of the vowel (Mode 2: synthesizes vowel, but does not show it)
         [stim,Fs,filename,dBreTONE,BASELINE_FormFreqs_Hz]= ...
            synth_BASELINE_eh(BASELINE_TargetFreq_Hz,BASELINE_F0_Hz,BASELINE_Feature,Fix2Harms,2);
         wavwrite(stim,Fs,fullfile(EHsignals_dir,filename))
      end
      
      %% From here, we just read the wavfile and proceed like ORIGINAL EH
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if (exist(stimulus_vals.Inloop.Compiled_FileName,'file') ~= 0)
         list = {stimulus_vals.Inloop.Compiled_FileName};
         [vowel BASELINE_Fs] = wavread(stimulus_vals.Inloop.Compiled_FileName);
      else
         list = {};
      end
      vowel=vowel*PolarityFact;  % Invert if necessary
      [stimulus_vals units] = NI_check_gating_params(stimulus_vals, units);
   
      % Generate TONE wavfile if necessary
      if strcmp(stimulus_vals.Inloop.use_TONE,'yes')
         TONEsamples=10;  % with Fs=33000, this gives f=3300, and allows (with NI board) up to 33kHz frequency tone!
                          % AND keeps major harmonic way above (9*f)
         BASETONE_TargetFreq_Hz=BASELINE_Fs/TONEsamples;  % make sure tone is periodic
         TONEfilename=sprintf('baseTONE_at%05.f.wav',BASETONE_TargetFreq_Hz);
         % If file does not exist, synthesize the new BASELINE tone and save as a new wavfile
         if isempty(dir(fullfile(EHsignals_dir,TONEfilename)))
            % stim is 1 cycle of a tone at the BASETONE_TargetFreq
            tone=sin(2*pi*BASETONE_TargetFreq_Hz*(0:TONEsamples-1)/BASELINE_Fs);
            wavwrite(tone,BASELINE_Fs,fullfile(EHsignals_dir,TONEfilename))
         end
      end
      
   end
   
   featureNames = {'T0','F1','T1','F2','T2','F3','T3','TN'};
   Features='';

   if ~BADstim
      % Call here to get params, later call to view vowel is needed
      [BASELINE_FeatFreqs_Hz,BASELINE_FeatLevs_dB,dBreTONE]= ...
         getVowelParams(vowel,BASELINE_Fs,stimulus_vals.Gating.Duration/1000,BASELINE_FormFreqs_Hz,0);
   else
      BASELINE_FeatFreqs_Hz=NaN*ones(size(featureNames));
      BASELINE_FeatLevs_dB=NaN*ones(size(featureNames));
      dBreTONE=NaN;
      BASELINE_Fs=33000;
      list={};
   end
   
   %% Create Feature vector
   if strcmp(stimulus_vals.Inloop.use_TONE,'yes'), Features{length(Features)+1}='TN';  end
   if strcmp(stimulus_vals.Inloop.use_T0,'yes'), Features{length(Features)+1}='T0';  end
   if strcmp(stimulus_vals.Inloop.use_F1,'yes'), Features{length(Features)+1}='F1';  end
   if strcmp(stimulus_vals.Inloop.use_T1,'yes'), Features{length(Features)+1}='T1';  end
   if strcmp(stimulus_vals.Inloop.use_F2,'yes'), Features{length(Features)+1}='F2';  end
   if strcmp(stimulus_vals.Inloop.use_T2,'yes'), Features{length(Features)+1}='T2';  end
   if strcmp(stimulus_vals.Inloop.use_F3,'yes'), Features{length(Features)+1}='F3';  end
   if strcmp(stimulus_vals.Inloop.use_T3,'yes'), Features{length(Features)+1}='T3';  end
      
   %  Create OctShift vector
   %  24Mar2005: M. Heinz: HARD CODED HERE
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %    CHANGE FOR Tone_reBF to go out to 1 octave
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   OctShifts=[-1.0 -.75 -.50 -.25 -.15 -.05 0 .05 .15 .25 .50 .75 1.0];
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %  Create Levels vector
   %  24Mar2005: M. Heinz: Max_level is a param, but Levels_list re max is HARD CODED HERE
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %    Levels_dBSPL=stimulus_vals.Inloop.Max_Level+[-30 -15 0];  % THREE LEVELS
   Levels_dBSPL=stimulus_vals.Inloop.Max_Level+[-30 -20 -10 0];  % THREE LEVELS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   
   %%%%%%%% Generate Lists here (fill in values for all REPS)
   featureIND_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Computed_FeatureTarget_Hz_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Computed_UpdateRate_Hz_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Used_UpdateRate_Hz_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Used_FeatureTarget_Hz_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Features_List=cell(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   OctShifts_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   Levels_dBSPL_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   list_List=cell(1,length(Features)*length(OctShifts)*length(Levels_dBSPL));
   dBreTONE_List=zeros(1,length(Features)*length(OctShifts)*length(Levels_dBSPL))+dBreTONE;
   
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% MH: 3/24/05 TODO
   % This is currently not working when I useTONE, some crash I can't find
   % fix the list assignment, including re-calc urate for TONE and anything else?
   % Get working - verify with TONE ALONE
   % fix *.Line. with error checks (CHECK ERROR CATCHING - does it work?)
   % SETUP tone-alone (with extra octshifts) and TEH
   % ADD RLFs
   % TEST ALL (verify tones, and triggering pulse OK
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   
   condIND=0;
   for FeatIND=1:length(Features)
      for shiftIND=1:length(OctShifts)
         for levelIND=1:length(Levels_dBSPL)
            condIND=condIND+1;
            Features_List{condIND}=Features{FeatIND};
            OctShifts_List(condIND)=OctShifts(shiftIND);
            Levels_dBSPL_List(condIND)=Levels_dBSPL(levelIND);
            
            featureIND_List(condIND)=find(strcmp(featureNames,Features(FeatIND)));
            %%% Same for TN and EH
            Computed_FeatureTarget_Hz_List(condIND)=stimulus_vals.Inloop.BaseFrequency*1000*2^(OctShifts(shiftIND));

            if strcmp(Features{FeatIND},'TN')
               list_List{condIND}=fullfile(EHsignals_dir,TONEfilename);
               dBreTONE_List(condIND)=0;
            else
               list_List{condIND}=fullfile(EHsignals_dir,filename);
            end
               
            %%% compute different updateRatenew for TONEs (based on BASETONE_TargetFreq)
            if ~BADstim
               if strcmp(Features{FeatIND},'TN')
                  Computed_UpdateRate_Hz_List(condIND)= ...
                     BASELINE_Fs*(Computed_FeatureTarget_Hz_List(condIND)/BASETONE_TargetFreq_Hz); %Shift to tone frequency
               else
                  Computed_UpdateRate_Hz_List(condIND)= ...
                     BASELINE_Fs*(Computed_FeatureTarget_Hz_List(condIND)/BASELINE_FeatFreqs_Hz(featureIND_List(condIND))); %Shift to feature
               end
            else
               Computed_UpdateRate_Hz_List(condIND)=BASELINE_Fs;
            end
            
            if (Computed_UpdateRate_Hz_List(condIND)> NI6052UsableRate_Hz(Inf))
               Used_UpdateRate_Hz_List(condIND)=NI6052UsableRate_Hz(Inf);
               nelerror('In EH_template: Requested sampling rate greater than MAX rate allowed by NI board!!');
            end
            Used_UpdateRate_Hz_List(condIND) = NI6052UsableRate_Hz(Computed_UpdateRate_Hz_List(condIND)); % GE/MH 04Nov2003:
            
            % Template forces use of a rate that is valid for the NI6052e board in the
            %  mode in which it is called (see 'd2a.c').
            Used_FeatureTarget_Hz_List(condIND)=Computed_FeatureTarget_Hz_List(condIND)* ...
               Used_UpdateRate_Hz_List(condIND)/Computed_UpdateRate_Hz_List(condIND);
            
            % Don't need to do this for TN feature
            if ~strcmp(Features{FeatIND},'TN')
               if ~BADstim
                  if strcmp(stimulus_vals.Inloop.ViewVowel,'shifted')
                     disp(sprintf('Showing: %s at %.3f octs',Features_List{condIND},OctShifts_List(condIND)));
                     [SHIFTED_FeatFreqs_Hz,SHIFTED_FeatLevs_dB,SHIFTED_dBreTONE]= ...
                        getVowelParams(vowel,Used_UpdateRate_Hz_List(condIND), ...
                        stimulus_vals.Gating.Duration/1000, ...
                        BASELINE_FormFreqs_Hz*Used_UpdateRate_Hz_List(condIND)/BASELINE_Fs,2);
                     if condIND==length(Used_UpdateRate_Hz_List)
                        stimulus_vals.Inloop.ViewVowel='no';  % Reset each time
                     else
                        input('Press Enter to continue');
                     end
                  end
               end
            end
            
         end
      end
   end
   if ~BADstim
      if strcmp(stimulus_vals.Inloop.ViewVowel,'baseline')
         [BASELINE_FeatFreqs_Hz,BASELINE_FeatLevs_dB,dBreTONE]= ...
            getVowelParams(vowel,BASELINE_Fs,stimulus_vals.Gating.Duration/1000,BASELINE_FormFreqs_Hz,1);
      end
   end
   stimulus_vals.Inloop.ViewVowel='no';  % Reset each time

   stimulus_vals.Inloop.OctShifts_List=OctShifts;

   stimulus_vals.Inloop.Computed_FeatureTarget_Hz_List=Computed_FeatureTarget_Hz_List;
   stimulus_vals.Inloop.Computed_UpdateRate_Hz_List=Computed_UpdateRate_Hz_List;
   stimulus_vals.Inloop.Used_UpdateRate_Hz_List=Used_UpdateRate_Hz_List;
   stimulus_vals.Inloop.Used_FeatureTarget_Hz_List=Used_FeatureTarget_Hz_List;
   
   Inloop.Name                         = 'DALinloop_NI_SCCi2_wavfiles';
   if strcmp(stimulus_vals.Inloop.use_TONE,'yes')
      Inloop.params.list                  = list_List;
   else
      Inloop.params.list                  = list;
   end
   
   Inloop.params.Condition.BaseFrequency_kHz            = stimulus_vals.Inloop.BaseFrequency;
   Inloop.params.Condition.OctShifts                    = OctShifts;
   Inloop.params.Condition.Features                     = Features; 
   Inloop.params.Condition.FormsAtHarmonics             = stimulus_vals.Inloop.FormsAtHarmonics;
   Inloop.params.Condition.InvertPolarity               = stimulus_vals.Inloop.InvertPolarity;
   Inloop.params.Condition.Levels_dBSPL                 = Levels_dBSPL;
   Inloop.params.CalibPicNum                 = stimulus_vals.Inloop.CalibPicNum;
   
   Inloop.params.BASELINE.F0_Hz              = BASELINE_F0_Hz;
   Inloop.params.BASELINE.Feature            = BASELINE_Feature; 
   Inloop.params.BASELINE.TargetFreq_Hz      = BASELINE_TargetFreq_Hz;
   Inloop.params.BASELINE.FormsAtHarmonics   = stimulus_vals.Inloop.FormsAtHarmonics;
   Inloop.params.BASELINE.FileName           = stimulus_vals.Inloop.Compiled_FileName;
   Inloop.params.BASELINE.FormFreqs_Hz       = BASELINE_FormFreqs_Hz;
   Inloop.params.BASELINE.dBreTONE           = dBreTONE;
   Inloop.params.BASELINE.Fs_Hz              = BASELINE_Fs;
   Inloop.params.BASELINE.FeatFreqs_Hz       = BASELINE_FeatFreqs_Hz;
   Inloop.params.BASELINE.FeatLevs_dB        = BASELINE_FeatLevs_dB;
   Inloop.params.featureNames                = featureNames;

   Inloop.params.Computed.FeatureTarget_Hz_List   = stimulus_vals.Inloop.Computed_FeatureTarget_Hz_List;
   Inloop.params.Computed.UpdateRate_Hz_List      = stimulus_vals.Inloop.Computed_UpdateRate_Hz_List;
   Inloop.params.Used.FeatureTarget_Hz_List       = stimulus_vals.Inloop.Used_FeatureTarget_Hz_List;
   Inloop.params.Used.UpdateRate_Hz_List          = stimulus_vals.Inloop.Used_UpdateRate_Hz_List;
   Inloop.params.Used.Levels_dBSPL_List           = Levels_dBSPL_List;
   
   
   %%% Account for Calibration to set Level in dB SPL
   if ~isempty(stimulus_vals.Inloop.CalibPicNum)
      if stimulus_vals.Inloop.CalibPicNum==0
         max_dBSPL=-999;
      else
         cdd
         if ~isempty(dir(sprintf('p%04d_calib.m',Inloop.params.CalibPicNum)))
            x=loadpic(stimulus_vals.Inloop.CalibPicNum);
            CalibData=x.CalibData(:,1:2);
            CalibData(:,2)=trifilt(CalibData(:,2)',5)';

            %%%%%%%%%%%%%%%%%%%%%
            %% 25Mar2005: MHeinz - 
            % Up until now, we had been using the Base_Target_Frequency
            %             max_dBSPL=CalibInterp(stimulus_vals.Inloop.BaseFrequency,CalibData);
            % BUT, it makes more sense to adjust the level based on the actual shifted Target Frequency
            %%%%%%%%%%%%%%%%%%%%%
            for i=1:length(stimulus_vals.Inloop.Used_FeatureTarget_Hz_List)
               max_dBSPL(i)=CalibInterp(stimulus_vals.Inloop.Used_FeatureTarget_Hz_List(i)/1000,CalibData);
            end
            
         else
            max_dBSPL=[];
            Inloop.params.CalibPicNum=NaN;
         end
         rdd
      end
   else
      max_dBSPL=[];
   end
   stimulus_vals.Inloop.Levels_dBSPL_List=Levels_dBSPL;
   if isempty(max_dBSPL)
      Inloop.params.attens                                   = [];
      stimulus_vals.Inloop.Computed_Attenuations_dB          = [];
   else
      Inloop.params.attens                                   = max_dBSPL-Levels_dBSPL_List+dBreTONE_List;
      stimulus_vals.Inloop.Computed_Attenuations_dB          = max_dBSPL(1:length(Levels_dBSPL))-Levels_dBSPL+min(dBreTONE_List);
   end
   
   Inloop.params.Rlist                 = []; % GE debug: will need to implement 2 channels eventually.
   Inloop.params.Rattens               = []; %      "
   Inloop.params.repetitions           = stimulus_vals.Inloop.Repetitions;
   
   %    Inloop.params.origstimUpdateRate_Hz = BASELINE_Fs;
   Inloop.params.Used.Features_List           = Features_List;
   Inloop.params.Used.OctShifts_List           = OctShifts_List;
   %    Inloop.params.featureFreq_Hz_List        = BASELINE_FeatFreqs_Hz(featureIND);
   %    Inloop.params.featureTargetFreq_Hz_List  = stimulus_vals.Inloop.Used_FeatureTarget_Hz_List;
   Inloop.params.updateRate_Hz         = stimulus_vals.Inloop.Used_UpdateRate_Hz_List;
     
   DAL.funcName = 'data_acquisition_loop_NI'; % added by GE 30oct2003.
   DAL.Inloop = Inloop;
   DAL.Gating = stimulus_vals.Gating;
   DAL.Mix         = mix_params2devs(stimulus_vals.Mix,used_devices); % GE debug: see 'used_devices.File' line at beginning of function
   DAL.short_description   = 'EHrBFi';
   
%    DAL.endLinePlotParams                  = nel_plot_pst_params(DAL.Gating.Period/1000, DAL.Gating.Duration/1000);  % GE 04Nov2003.

   DAL.description = build_description(DAL,stimulus_vals);
   errstr = check_DAL_params(DAL,fieldname);
end

%----------------------------------------------------------------------------------------
function str = build_description(DAL,stimulus_vals)
p = DAL.Inloop.params;
[fpath,file] = fileparts(stimulus_vals.Inloop.Compiled_FileName);

str{1} = sprintf('%dreps:', p.repetitions);
str{1} = sprintf('%s ''%s''', str{1},file);
str{1} = sprintf('%s(%s), ', str{1}, stimulus_vals.Mix.File(1));
for i=1:length(p.Condition.Levels_dBSPL)
   str{1} = sprintf('%s%1.1f|', str{1}, p.Condition.Levels_dBSPL(i));
end
str{1} = sprintf('%sdB SPL,', str{1}(1:end-1));
for i=1:length(DAL.Inloop.params.Condition.Features)
   if i==1
      FeaturesText=DAL.Inloop.params.Condition.Features{i};
   else
      FeaturesText=strcat(FeaturesText,'|',DAL.Inloop.params.Condition.Features{i});
   end
end   
str{1} = sprintf('%s %s,', str{1},FeaturesText);
str{1} = sprintf('%s @%.3f kHz+%.2f:%.2foct', str{1},stimulus_vals.Inloop.BaseFrequency,stimulus_vals.Inloop.OctShifts_List(1),stimulus_vals.Inloop.OctShifts_List(end));
if strcmp(stimulus_vals.Inloop.InvertPolarity,'yes')
   str{1} = sprintf('%s (Pol:-)', str{1});
else
   str{1} = sprintf('%s (Pol:+)', str{1});
end
str{1} = sprintf('%s (%d conds)', str{1},length(DAL.Inloop.params.attens));
   
%----------------------------------------------------------------------------------------
function errstr = check_DAL_params(DAL,fieldname)
% Some extra error checks
errstr = '';
if (isequal(fieldname,'Inloop'))
   if isnan(DAL.Inloop.params.BASELINE.dBreTONE)  % Indicates BADstim!!!
      errstr=sprintf('Problem with stimulus design!!  BASELINE formants were: %.1f, %.1f, %.1f, %.1f, %.1f Hz ',DAL.Inloop.params.BASELINE.FormFreqs_Hz);
   else
      if isempty(DAL.Inloop.params.CalibPicNum)
         errstr = 'Need to set Calibration PicNum!';
      elseif isnan(DAL.Inloop.params.CalibPicNum)
         errstr = 'Not a valid Calibration PicNum! (use 0 to escape)';      
      elseif DAL.Inloop.params.CalibPicNum==0
         errstr = '';      % Allows you to escape the structdlg to go find a valid calibration file
      else
         if (isempty(DAL.Inloop.params.attens))
            errstr = 'Attenuations are not set correctly! (high vs. low mismatch?)';
         elseif (min(DAL.Inloop.params.attens)<0)
            errstr = sprintf('Negative Attenuation of %.1f dB cannot be set, Max_Level must be lowered',min(DAL.Inloop.params.attens));
         elseif (max(DAL.Inloop.params.attens)>120)
            errstr = sprintf('Attenuation of %.1f dB cannot be set, Min_Level must be raised',max(DAL.Inloop.params.attens));
         elseif sum(isnan(DAL.Inloop.params.Computed.UpdateRate_Hz_List))
            errstr = 'Computed UpdateRate is NaN, one chosen feature is undefined!!';
         end
      end
   end
end

%----------------------------------------------------------------------------------------
function tmplt = template_definition(fieldname)
global signals_dir
persistent prev_unit_bf
%%%%%%%%%%%%%%%%%%%%
%% Inloop Section 
%%%%%%%%%%%%%%%%%%%%
IO_def.Inloop.BaseFrequency     =  {'current_unit_bf'   'kHz'      [0.04  50] 0 0};
IO_def.Inloop.Max_Level  =  {90 'dB SPL'       [-50    150]   0  0}; 
IO_def.Inloop.use_TONE         =  {'no|{yes}'};
IO_def.Inloop.use_T0           =  {'{no}|yes'};
IO_def.Inloop.use_F1           =  {'{no}|yes'};
IO_def.Inloop.use_T1           =  {'{no}|yes'};
IO_def.Inloop.use_F2           =  {'{no}|yes'};
IO_def.Inloop.use_T2           =  {'{no}|yes'};
IO_def.Inloop.use_F3           =  {'{no}|yes'};
IO_def.Inloop.use_T3           =  {'{no}|yes'};
IO_def.Inloop.FormsAtHarmonics =  {'no|{yes}'};
IO_def.Inloop.InvertPolarity   =  {'{no}|yes'};
IO_def.Inloop.Repetitions  =  {50   ''       [1 600]}; 
IO_def.Inloop.CalibPicNum  =  {[]   ''       [0 6000]};
IO_def.Inloop.ViewVowel  =  {'{no}|baseline|shifted'};

if (~isequal(current_unit_bf, prev_unit_bf) & isequal(fieldname,'Inloop'))
   IO_def.Inloop.BaseFrequency{5}            = 1; % ignore dflt. Always recalculate.
   prev_unit_bf = current_unit_bf;
end


%%%%%%%%%%%%%%%%%%%%
%% Gating Section 
%%%%%%%%%%%%%%%%%%%%
IO_def.Gating.Duration             = {400       'ms'    [20 2000]};
IO_def.Gating.Period               = {'default_period(this.Duration)'    'ms'   [50 5000]};
IO_def.Gating.Rise_fall_time       = {'default_rise_time(this.Duration)' 'ms'   [0  1000]};

%%%%%%%%%%%%%%%%%%%%
%% Mix Section 
%%%%%%%%%%%%%%%%%%%%
IO_def.Mix.File        =  {'Left|Both|{Right}'};

tmplt.tag               = 'TONErBFi_tmplt';
tmplt.IO_def = IO_def;
