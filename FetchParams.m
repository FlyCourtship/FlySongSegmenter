%script to set default parameters, and load user specified changes.
%
%the values below are overwritten by the custom parameter file specified as an input
%argument to FlySongSegmenter and fly_song_segmenter, or, if that is not specified,
%by params.m

%SET DEFAULT PARAMETERS

Params.Fs = 10000;                    % sampling frequency, in Hertz
Params.keep_mediumrare_data = true;   % if false, Sines.MultiTaper.A, Sines.*.clips, Pulses.cmh*,
                                      %     Pulses.*.x, and Pulses.pulse_model*.allZ* are not saved
Params.copy_raw_data = true;          % if false, Data.d/hyg/daqinfo are not saved in the .mat file

%estimating noise
Params.low_freq_cutoff = 100;         % exclude data below this frequency
Params.high_freq_cutoff = 1000;       % exclude data above this frequency
Params.cutoff_sd = 3;                 % exclude data above this multiple of the std. deviation

%pulse song:  wavelet transform
Params.fc = [100:25:750];             % wavelet scales, in Hertz
Params.DoGwvlt = [2:3];               % Derivative of Gaussian wavelets examined

%pulse song:  segment
Params.pWid = round(Params.Fs/250)+1; % approx pulse width, in ticks (odd, rounded)
Params.minIPI = round(Params.Fs/100); % lowest acceptable IPI, in ticks (even, rounded)
Params.thresh = 4;                    % multiple of smoothed threshold over which pulses are counted

%pulse song:  cull with heuristics
Params.minAmplitude  = 6;             %multiple of the mean noise which pulses must exceed
Params.maxIPI = round(Params.Fs/5);   %if no other pulse within this many ticks, do not count as a pulse
Params.frequency = 700;               %if best matched scale is greater than this frequency, do not count as a pulse
Params.close = round(Params.Fs/50);   %if pulse peaks are this close together, only keep the larger pulse

%pulse song:  cull with model
Params.pulse_model='pulse_model_melanogaster.mat';

%find sine song?  Code is MUCH faster if you don't search for sine.
Params.find_sine = true;

% sine song:  multi-taper
Params.NW = 12;                       % time-bandwidth product for tapers
Params.K = 20;                        % numver independent tapers to average over, must be < 2*NW
Params.dT = 0.1;                      % FFT window length, in seconds
Params.dS = 0.01;                     % FFT window step size, in seconds
Params.pval = 0.05;                   % criterion for F-test
Params.fwindow = [0 Params.Fs];       % frequency range to analyze, in Hertz

%sine song:  segment
Params.sine_low_freq = 100;           % lowest frequency to include as sine, in Hertz
Params.sine_high_freq = 300;          % highest frequency to include as sine, in Hertz
Params.sine_range_percent = 0.2;      % tolerance to merge harmonically-related frequencies
Params.discard_less_n_steps = 3;      % minimum length for sine song, in dS

%sine song:  winnow
Params.max_pulse_pause = 0.200; %max_pulse_pause in seconds, used to winnow apparent sine between pulses
Params.mask_pulses = 'ModelCull2';


%READ IN USER DEFINED PARAMETERS, SOME OF WHICH MAY REPLACE DEFAULTS
if ~exist('params_path', 'var') || isempty(params_path)
    params;
else
%    run(params_path);
    fid = fopen(params_path);
    if fid < 0
        error('Could not open the parameters file at %s', params_path);
    end
    params_code = fread(fid, '*char')';
    fclose(fid);
    try
%        disp(params_code);
        eval(params_code);
    catch ME
        error('Could not load the parameters from %s (%s)', params_path, ME.message);
    end
end

load(Params.pulse_model);
