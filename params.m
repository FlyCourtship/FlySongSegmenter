 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%ALL USER DEFINED PARAMETERS ARE SET HERE%%%%%%%%%%%%%%%%%%%%%

%SET THE PARAMETERS FOR SineSegmenter
Fs=10000;
NW = 12;%NW = time-bandwidth product for tapers
K = 20;%K = num independent tapers to average over, must be < 2*NW
dT = 0.1;%dT = window length
dS = 0.01;%dS = window step size
pval = 0.05;%pval = criterion for F-test
fwindow = [0 Fs/2];%[0 1000] if want up to Nyquist freq


%find sine song? Toggle: 1 = yes; 0 = no. Code is MUCH faster if you don't
%search for sine.
find_sine = 1;

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

%SET THE PARAMETERS FOR putativepulse3(ssf,sine,noise_ssf,cutoff_quantile,range,combine_time)
%cutoff_quantile will be deprecated to cutoff_sd
cutoff_quantile = 0.95;%used when user supplies separate noise file %was 0.99
cutoff_sd = 3;%used when only signal file is provided
%user definable parameters to increase range of putative pulse
range = 1.3;%expand putative pulse by this number of steps on either side
combine_time = 5;%combine putative pulse if within this step size. i.e. this # * step_size in ms 
low_freq_cutoff = 80;
high_freq_cutoff = 1000;
noise_cutoff = 0.9;

%SET THE PARAMETERS FOR PulseSegmentation

%general parameters:
a = [100:25:750]; %wavelet scales: frequencies examined.
b = [2:3]; %Derivative of Gaussian wavelets examined (2:3)
c = round(Fs/250)+1; %pWid:  Approx Pulse Width in points (odd, rounded)
d = round(Fs/100); %lowIPI: estimate of a very low IPI (even, rounded)
e = 5; %thresh:Proportion of smoothed threshold over which pulses are counted. 

%parameters for winnowing pulses: 
%first winnow: (returns pulseInfo)
f = 6; %factor times the mean of xempty - only pulses larger than this amplitude are counted as true pulses

%second winnow: (returns pulseInfo2)
g = round(Fs/5); %if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse, not within IPI range of another pulse, is likely not a true pulse)
h = 700; %if best matched scale is greater than this frequency, then don't include pulse as true pulse
i = round(Fs/50); %if pulse peaks are this close together, only keep the larger pulse (this value should be less than the species-typical IPI)

%SET THE PARAMETERS FOR WinnowSine
max_pulse_pause = 0.070; %max_pulse_pause in seconds, used to winnow apparent sine between pulses

%SET THE PARAMETERS FOR Z_2_pulse_model and cull_pulses
load('mel_pm_24ii12.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
