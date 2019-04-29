function mic = mic007c;
% Calibration file for Etymotic ER-7c probe microphone.
% dBV = absolute mic calib = dB re 1V from B&K amp with 0 dB B&K gain
%      and an input signal of 124 dB SPL at 250 Hz (e.g. from pistonphone).
% CalData column 1 is frequency in kHz.
%         column 2 is gain calib, so dBSPL=dBre1V-dBV+column2.
%			    (to get the probe correction, subtract 124 dB.). NOTE saturated at 164 dB manually
%         column 3 is phase correction, phase = phase from lockin + column 3.
%			    (note, no unwrapping has been done.)
% Below is with Etymotic amp's gain set at 0 dB.


mic = struct('number', 88631, 'probename', '007c', ...
      'date', '31-May-2005 ', ...
      'preamp', 0, 'S0', 0, 'expect', 0, ...
      'dBV', 4.2, ...
      'CalData', {[
        0.196983, 124.1, 0.0;
        0.211121, 124.0, 0.0;
        0.226274, 124.1, 0.0;
        0.242515, 124.1, 0.0;
        0.259921, 124.1, 0.0;
        0.278576, 124.1, 0.0;
        0.298571, 124.1, 0.0;
        0.32, 124.1, 0.0;
        0.342968, 124.2, 0.0;
        0.367583, 124.2, 0.0;
        0.393966, 124.3, 0.0;
        0.422243, 124.25, 0.0;
        0.452548, 124.25, 0.0;
        0.485029, 124.2, 0.0;
        0.519842, 124.2, 0.0;
        0.557152, 124.225, 0.0;
        0.597141, 124.225, 0.0;
        0.64, 124.25, 0.0;
        0.685935, 124.25, 0.0;
        0.735167, 124.3, 0.0;
        0.787932, 124.3, 0.0;
        0.844485, 124.225, 0.0;
        0.905097, 124.225, 0.0;
        0.970059, 124.21, 0.0;
        1.03968, 124.2, 0.0;
        1.1143, 124.2, 0.0;
        1.19428, 124.15, 0.0;
        1.28, 124.15, 0.0;
        1.37187, 124.15, 0.0;
        1.47033, 124.1, 0.0;
        1.57586, 124.0, 0.0;
        1.68897, 123.7, 0.0;
        1.81019, 123.5, 0.0;
        1.94012, 123.4, 0.0;
        2.07937, 123.3, 0.0;
        2.22861, 123.3, 0.0;
        2.38856, 123.4, 0.0;
        2.56, 123.45, 0.0;
        2.74374, 123.6, 0.0;
        2.94067, 123.8, 0.0;
        3.15173, 124.15, 0.0;
        3.37794, 123.8, 0.0;
        3.62039, 123.9, 0.0;
        3.88023, 123.7, 0.0;
        4.15873, 123.2, 0.0;
        4.45722, 123.2, 0.0;
        4.77713, 123.2, 0.0;
        5.12, 123.6, 0.0;
        5.48748, 123.4, 0.0;
        5.88134, 123.2, 0.0;
        6.30346, 122.8, 0.0;
        6.75588, 123.2, 0.0;
        7.24077, 124.0, 0.0;
        7.76047, 123.7, 0.0;
        8.31746, 123.4, 0.0;
        8.91444, 123.5, 0.0;
        9.55426, 123.7, 0.0;
        10.24, 123.2, 0.0;
        10.975, 123.2, 0.0;
        11.7627, 123.1, 0.0;
        12.6069, 122.7, 0.0;
        13.5118, 123.0, 0.0;
        14.4815, 122.7, 0.0;
        15.5209, 122.9, 0.0;
        16.6349, 123.3, 0.0;
        17.8289, 123.4, 0.0;
        19.1085, 125.7, 0.0;
        20.48, 128.7, 0.0;
       ]});