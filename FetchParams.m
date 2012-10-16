%Script to set Paramseters

%%%%%%%%%%%
%%DEFAULT PARAMATERS
%%%%%%%%%%%

Params.Fs = 10000;
Params.NW = 12;%NW = time-bandwidth product for tapers
Params.K = 20;%K = num independent tapers to average over, must be < 2*NW
Params.dT = 0.1;%dT = window length
Params.dS = 0.01;%dS = window step size
Params.pval = 0.05;%pval = criterion for F-test
Params.fwindow = [0 Params.Fs];%[0 1000] if want up to Nyquist freq

%find sine song? Toggle: 1 = yes; 0 = no. Code is MUCH faster if you don't
%search for sine.
Params.find_sine = 1;


%SET THE PARAMETERS FOR lengthfinder3
%freq1 and freq2 define the bounds between which the fundamental frequency 
%of sine song is expected
Params.sine_low_freq = 100;%lowest frequency to include as sine
Params.sine_high_freq = 300;%highest frequency to include as sine
%search within ± this percent to determine whether consecutive events are
%continuous sine
Params.sine_range_percent = 0.2;
%remove putative sine smaller than n events long
Params.discard_less_n_steps = 3;

%SET THE PARAMETERS FOR putativepulse2(ssf,sine,noise_ssf,cutoff_quantile,range,combine_time)
Params.cutoff_quantile = 0.99;%this Paramseter will be deprecated to cutoff_sd
Params.cutoff_sd = 3;
%user definable Paramseters to increase range of putative pulse
Params.range = 1.3;%expand putative pulse by this number of steps on either side
Params.combine_time = 15;%combine putative pulse if within this step size. i.e. this # * step_size in ms
Params.low_freq_cutoff = 100;
Params.high_freq_cutoff = 1000;

%SET THE PARAMETERS FOR PulseSegmentation

%general Paramseters:
%a = [100:25:900]; %wavelet scales: frequencies examined. 
%b = Fs; %sampling frequency
%c = [2:4]; %Derivative of Gaussian wavelets examined
%d = round(Fs/2000);  %Minimum distance for DoG wavelet peaks to be considered separate. (peak detection step) If you notice that individual cycles of the same pulse are counted as different pulses, increase this Paramseter
%e = round(Fs/1000); %Minimum distance for morlet wavelet peaks to be considered separate. (peak detection step)                            
%f = round(Fs/4000); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse, and sets the Paramsters w0 and w1.)
%
%%Paramseters for winnowing pulses:
%g = 5; %factor times the mean of xempty - only pulses larger than this amplitude are counted as true pulses
%h = round(Fs/50); % Width of the window to measure peak-to-peak voltage for a single pulse
%i = round(Fs/2); %if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse, not within IPI range of another pulse, is likely not a true pulse)
%j = 3; %if pulse peak height is more than j times smaller than the pulse peaks on either side (within 100ms), don't include
%k = 900; %if best matched scale is greater than this frequency, then don't include pulse as true pulse
%l = round(Fs/100); %if pulse peaks are this close together, only keep the larger pulse
%m = 99;     % Power percentile at and above which a clip is marked as signal rather than noise.

%general Paramseters:
Params.fc = [100:25:750]; %wavelet scales: frequencies examined.
Params.DoGwvlt = [2:3]; %Derivative of Gaussian wavelets examined (2:3)
Params.pWid = round(Params.Fs/250)+1; %pWid:  Approx Pulse Width in points (odd, rounded)
Params.lowIPI = round(Params.Fs/100); %lowIPI: estimate of a very low IPI (even, rounded)
Params.thresh = 4; %thresh:Proportion of smoothed threshold over which pulses are counted. 

%Paramseters for winnowing pulses: 
%first winnow: (returns pulseInfo)
Params.wnwMinAbsVoltage  = 6; %factor times the mean of xempty - only pulses larger than this amplitude are counted as true pulses

%second winnow: (returns pulseInfo2)
Params.IPI = round(Params.Fs/5); %if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse, not within IPI range of another pulse, is likely not a true pulse)
Params.frequency = 700; %if best matched scale is greater than this frequency, then don't include pulse as true pulse
Params.close = round(Params.Fs/50); %if pulse peaks are this close together, only keep the larger pulse (this value should be less than the species-typical IPI)

%SET THE PARAMETERS FOR WinnowSine
Params.max_pulse_pause = 0.200; %max_pulse_pause in seconds, used to winnow apparent sine between pulses
Params.mask_pulses = 'ModelCull2';

%SET THE PARAMETERS FOR FitPulseModel and CullPulses
Params.pulse_model='pulse_model_melanogaster.mat';

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
%        disp(params_code);
        eval(params_code);
    catch ME
        error('Could not load the parameters from %s (%s)', params_path, ME.message);
    end
end

load(Params.pulse_model);


%%%%%%%%%%%%%%%%%
%%READ PARAMETERS INTO STRUCTURE ARRAY TO BE USED BY FlySongSegmenter
%%%%%%%%%%%%%%%%%

%Params.NW = NW;
%Params.K = K;
%Params.dT = dT;
%Params.dS = dS;
%Params.pval = pval;
%Params.find_sine = find_sine;
%Params.sine_low_freq = sine_low_freq;
%Params.sine_high_freq = sine_high_freq;
%Params.sine_range_percent = sine_range_percent;
%Params.discard_less_n_steps = discard_less_n_steps;
%Params.cutoff_quantile = cutoff_quantile;
%Params.cutoff_sd = cutoff_sd;
%Params.range = range;
%Params.combine_time = combine_time;
%Params.low_freq_cutoff = low_freq_cutoff;
%Params.high_freq_cutoff = high_freq_cutoff;
%Params.Fs = Fs;
%Params.fwindow = fwindow;
%Params.a = a;
%Params.b = b;
%Params.c = c;
%Params.d = d;
%Params.e = e;
%Params.f = f;
%Params.g = g;
%Params.h = h;
%Params.i = i;
%Params.j = j;
%Params.k = k;
%Params.l = l;
%Params.m = m;
%Params.max_pulse_pause = max_pulse_pause;
%
%clear NW K dT dS pval sine_low_freq sine_high_freq sine_range_percent ...
%    discard_less_n_steps cutoff_quantile range combine_time Fs a b c ...
%    d e f g h i j k l m max_pulse_pause
