function update_inhibit_params					%function to rewrite parameter fileglobal PARAMS PROG VERSION			   %these are the global variables to be stored								global root_dir NelDatafeval('save',fullfile(root_dir,'inhibit','workspace','tcbjm'),'PARAMS','PROG','VERSION');clear get_inhibit_ins;%parameter files are stored under the subject's name in the subjects directory%file_name = fullfile(root_dir,'tuning_curve','get_tc_ins.m');file_name = fullfile(root_dir,'..','Users',NelData.General.User,'get_inhibit_ins.m');fid = fopen(file_name,'wt');					%open file ID as as a writeable text file (text files are easy to read and portable)fprintf(fid,'%s\n','%Inhibition Curve Maker Instruction Block');		%the following print statements convert parameters to lines of text in parameter filefprintf(fid,'%s\n\n','%M. Sayles (2014)');		%the following print statements convert parameters to lines of text in parameter filefprintf(fid,'%s%6.3f%c\t\t\t%s\n','frqlo   =',PARAMS(1),';','%low frequency (in kHz) bounds for data');fprintf(fid,'%s%6.3f%c\t\t\t%s\n','frqhi   =',PARAMS(2),';','%high frequency (in kHz) bounds for data');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'fstlin  =',PARAMS(3),';','% # of linear frequency steps (set = 0 for log steps)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'fstoct  =',PARAMS(4),';','% # of log freq. steps (per oct. OR per 10-dB BW for Qspaced) (= 0 for lin steps; NEGATIVE for Qspaced)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'attlo   =',PARAMS(5),';','%low atten (in dB atten) for auto tracking');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'atthi   =',PARAMS(6),';','%high atten (in dB atten) for auto tracking');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'attstp  =',PARAMS(7),';','%size of initial attenuation steps (in dB atten) for auto tracking');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'match2  =',PARAMS(8),';','%number of threshod replications (1 or 2)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'crit    =',PARAMS(9),';','%number of sps above spont for response');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'ear     =',PARAMS(10),';','%ear code (lft = 1, rgt = 2, both = 3');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'ToneOn  =',PARAMS(11),';','%duration of tone presentation');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'ToneOff =',PARAMS(12),';','%duration of interstim interval');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'RespWin1=',PARAMS(13),';','%start of window for sampling resp');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'RespWin2=',PARAMS(14),';','%end of window for sampling resp');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'CFAtt=',PARAMS(15),';','%CF tone attenuation (fixed)');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'CFFreq=',PARAMS(16),';','%CF tone frequency (fixed)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'AnalysisType=',PARAMS(17),';','%1 = suppression tuning curve, 2 = suppression growth function, 3 = adaptation growth function');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'GrowthFreqLo=',PARAMS(18),';','%kHz - lower limit for suppressor freq in growth functions');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'GrowthFreqHi=',PARAMS(19),';','%kHz - upper limit for suppressor freq in growth functions');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'GrowthFreqStep=',PARAMS(20),';','%octaves re. CF. Set to 0 to specify individual frequencies');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'GrowthFreqs=',PARAMS(21),';','% kHz, can use this to input specific frequencies of interest, otherwise set to 0');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'GrowthLevelStart=',PARAMS(22),';','%Starting attenuation level for the growth function');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'GrowthLevelStep=',PARAMS(23),';','%Step size (dB) for the growth function');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'GrowthCriterion=',PARAMS(24),';','%Criterion spike rate to track for growth function (Ideally, re-set to 2/3 max. rate from CF-tone IOFn)');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'maskerF=',PARAMS(25),';','%Fixed Masker Frequency (in kHz)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'maskerdBSPL=',PARAMS(26),';','%Fixed Masker Level (in dBSPL)');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'CalibPicNum=',PARAMS(27),';','%Calibration picture number');fprintf(fid,'%s%6d%c\t\t\t%s\n'  ,'minDeltaT=',PARAMS(28),';','%Minimum Delta T in recovery function (in ms)');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'maxDeltaT=',PARAMS(29),';','%Maximum Delta T in recovery function (in ms)');fprintf(fid,'%s%6.3f%c\t\t\t%s\n'  ,'DeltaTStep=',PARAMS(30),';','%Delta T step (in octaves)');fclose(fid);	%close the file and return to parameter change function