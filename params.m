% use this file to change the default parameters found, together with documentation, in FetchParams.m
 
Params.Fs=10000;

Params.low_freq_cutoff = 80;
Params.high_freq_cutoff = 1000;
Params.cutoff_sd = 3;

Params.fc = [100:25:750];
Params.DoGwvlt = [2:3];

Params.pWid = round(Params.Fs/250)+1;
Params.minIPI = round(Params.Fs/100);
Params.thresh = 4;

Params.wnwMinAbsVoltage   = 6;
Params.maxIPI = round(Params.Fs/5);
Params.frequency = 700;
Params.close = round(Params.Fs/50);

Params.pulse_model='pulse_model_melanogaster.mat';

Params.find_sine = true;

Params.NW = 12;
Params.K = 20;
Params.dT = 0.1;
Params.dS = 0.01;
Params.pval = 0.05;
Params.fwindow = [0 Params.Fs/2];

Params.sine_low_freq = 100;
Params.sine_high_freq = 300;
Params.sine_range_percent = 0.2;
Params.discard_less_n_steps = 3; 

Params.max_pulse_pause = 0.070;
Params.mask_pulses = 'ModelCull2';
