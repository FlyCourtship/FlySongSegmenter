%Script to set parameters

%%%%%%%%%%%
%%DEFAULT PARAMATERS
%%%%%%%%%%%

Fs = 10000;
NW = 12;%NW = time-bandwidth product for tapers
K = 20;%K = num independent tapers to average over, must be < 2*NW
dT = 0.1;%dT = window length
dS = 0.01;%dS = window step size
pval = 0.05;%pval = criterion for F-test
fwindow = [0 Fs];%[0 1000] if want up to Nyquist freq

%SET THE PARAMETERS FOR lengthfinder3
%freq1 and freq2 define the bounds between which the fundamental frequency 
%of sine song is expected
sine_low_freq = 100;%lowest frequency to include as sine
sine_high_freq = 300;%highest frequency to include as sine
%search within ± this percent to determine whether consecutive events are
%continuous sine
sine_range_percent = 0.2;
%remove putative sine smaller than n events long
discard_less_n_steps = 3;

%SET THE PARAMETERS FOR putativepulse2(ssf,sine,noise_ssf,cutoff_quantile,range,combine_time)
cutoff_quantile = 0.99;%this parameter will be deprecated to cutoff_sd
cutoff_sd = 3;
%user definable parameters to increase range of putative pulse
range = 1.3;%expand putative pulse by this number of steps on either side
combine_time = 15;%combine putative pulse if within this step size. i.e. this # * step_size in ms
low_freq_cutoff = 100;
high_freq_cutoff = 1000;

%SET THE PARAMETERS FOR PulseSegmentation

%general parameters:
a = [100:25:900]; %wavelet scales: frequencies examined. 
b = Fs; %sampling frequency
c = [2:4]; %Derivative of Gaussian wavelets examined
d = round(Fs/2000);  %Minimum distance for DoG wavelet peaks to be considered separate. (peak detection step) If you notice that individual cycles of the same pulse are counted as different pulses, increase this parameter
e = round(Fs/1000); %Minimum distance for morlet wavelet peaks to be considered separate. (peak detection step)                            
f = round(Fs/4000); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse, and sets the paramters w0 and w1.)

%parameters for winnowing pulses:
g = 5; %factor times the mean of xempty - only pulses larger than this amplitude are counted as true pulses
h = round(Fs/50); % Width of the window to measure peak-to-peak voltage for a single pulse
i = round(Fs/2); %if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse, not within IPI range of another pulse, is likely not a true pulse)
j = 3; %if pulse peak height is more than j times smaller than the pulse peaks on either side (within 100ms), don't include
k = 900; %if best matched scale is greater than this frequency, then don't include pulse as true pulse
l = round(Fs/100); %if pulse peaks are this close together, only keep the larger pulse
m = 99;     % Power percentile at and above which a clip is marked as signal rather than noise.

%SET THE PARAMETERS FOR winnow_sine
max_pulse_pause = 0.200; %max_pulse_pause in seconds, used to winnow apparent sine between pulses

%%%%%%%%%%%%%%%%%
%%READ IN USER DEFINED PARAMETERS, SOME OF WHICH MAY REPLACE DEFAULTS
%%%%%%%%%%%%%%%%%
if ~exist('params_path', 'var') || isempty(params_path)
    params;
else
    fid = fopen(params_path);
    if fid < 0
        error('Could not open the parameters file at %s', params_path);
    end
    params_code = fread(fid, '*char')';
    fclose(fid);
    try
        eval(params_code);
    catch ME
        error('Could not load the parameters from %s (%s)', params_path, ME.message);
    end
end

%%%%%%%%%%%%%%%%%
%%READ PARAMETERS INTO STRUCTURE ARRAY TO BE USED BY Process_Song
%%%%%%%%%%%%%%%%%

param.NW = NW;
param.K = K;
param.dT = dT;
param.dS = dS;
param.pval = pval;
param.sine_low_freq = sine_low_freq;
param.sine_high_freq = sine_high_freq;
param.sine_range_percent = sine_range_percent;
param.discard_less_n_steps = discard_less_n_steps;
param.cutoff_quantile = cutoff_quantile;
param.cutoff_sd = cutoff_sd;
param.range = range;
param.combine_time = combine_time;
param.low_freq_cutoff = low_freq_cutoff;
param.high_freq_cutoff = high_freq_cutoff;
param.Fs = Fs;
param.fwindow = fwindow;
param.a = a;
param.b = b;
param.c = c;
param.d = d;
param.e = e;
param.f = f;
param.g = g;
param.h = h;
param.i = i;
param.j = j;
param.k = k;
param.l = l;
param.m = m;
param.max_pulse_pause = max_pulse_pause;

clear NW K dT dS pval sine_low_freq sine_high_freq sine_range_percent ...
    discard_less_n_steps cutoff_quantile range combine_time Fs a b c ...
    d e f g h i j k l m max_pulse_pause
