%CAP Instruction Block

interface_type = 'fmasked_CAPs';

misc = struct( ... 
   'fileExtension', 'fmasked_CAP', ...
   'saveMat', true...  %if False save .m files
  ); 

Stimuli = struct( ...
   'atten_dB', 20, ...  %click atten
   'masker_atten_dB', 30, ... %masker atten
   'fast', struct( ...
          'duration_ms',50, ...   %Masker On (total duration)
          'rftime_ms',  8, ...  %Gating time WARNING!: this value is hard coded in RPvdsEx (CosGate), must be duplicated
          'period_ms',  80, ... %67  %Time between two onsets of stimuli (maskers) - = 'StmOff' + duration_ms 
          'XstartPlot_ms',0, ...
          'XendPlot_ms',16, ...
          'CAPlength_ms',16, ...
          'clickDelay', 10), ... 
   'slow', struct( ... %no change compared to fast for now but could be useful in other settings
          'duration_ms', 50, ...
          'rftime_ms',  8, ...
          'period_ms',  80, ...
          'XstartPlot_ms',0, ...
          'XendPlot_ms',16, ...
          'CAPlength_ms',16, ...
          'clickDelay', 10), ...
   'fixedPhase', 0,  ...
   'channel',   3, ...
   'KHosc',     0, ...
   'CAPmem_reps',  30, ...
   'threshV', 2, ... %for artifact rejection KH 2012 Jan 05
   'ear', 'both' ...  % set in CAP.m
   );

 RunLevels_params = struct( ... 
    'nPairs', 10, ...
    'decimateFact', 1, ...
    'saveRepsYes', 1,...
    'shuffleFiles', 1, ...  %shuffle filenames (for interleaving)
    'loadWavefiles', 0, ... %if false (0), stimuli are generated on the fly
    'invFilterOnWavefiles', 1, ...  %apply inverse filter directly on generated wavefiles (only possible when loadWavefiles is False
    'lpcInvFilterOnClick', 1,...  %apply inverse filter (estimated with lpc coeff) on click (will generate a wavefile), needs specific calibration to be performed at first launch of app.
    'extraAttenuationOnWavefiles', 0 ... %if 1, apply extra attenuation on wavefiles (check consistency with 'loadWavefiles'), else extra attenuation is included to the total attenuation
); %NB - structure actually used for RunStimuli
     %'bMultiOutputFiles', 0 ...  %not useful, 1 file per stimuli by
     %default

Display = struct( ... 
 'Gain', 1000, ...  
 'YLim_atAD', 0.8, ...
 'Voltage', 'atELEC' ...
 ); 

     
Stimuli.RPsamprate_Hz= 48828; %12207.03125;  % Hard coded for now, eventually get from RP
              
% MH/GE 11/03/03: eventually add a param for AD channel
