%Search Instruction Block

Stimuli = struct('freq_hz',5000, ...
    'freq_list',round(logspace(log10(200),log10(20000),25)), ...
    'atten',    50, ...
    'duration', 50, ...
    'period',  250, ...
    'channel',   3, ...
    'KHosc',     0, ...
    'fmult',    10, ...
    'spike_channel', 1);   % added by GE 17Jan2003.

