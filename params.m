 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%ALL USER DEFINED PARAMETERS ARE SET HERE%%%%%%%%%%%%%%%%%%%%%

%SET THE PARAMETERS FOR MultiTaperFTest
Params.Fs=10000;
Params.NW = 12;%NW = time-bandwidth product for tapers
Params.K = 20;%K = num independent tapers to average over, must be < 2*NW
Params.dT = 0.1;%dT = window length
Params.dS = 0.01;%dS = window step size
Params.pval = 0.05;%pval = criterion for F-test
Params.fwindow = [0 Params.Fs/2];%[0 1000] if want up to Nyquist freq


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

%SET THE PARAMETERS FOR putativepulse3(ssf,sine,noise_ssf,cutoff_quantile,range,combine_time)
%cutoff_quantile will be deprecated to cutoff_sd
Params.cutoff_quantile = 0.95;%used when user supplies separate noise file %was 0.99
Params.cutoff_sd = 3;%used when only signal file is provided
%user definable Paramseters to increase range of putative pulse
Params.range = 1.3;%expand putative pulse by this number of steps on either side
Params.combine_time = 5;%combine putative pulse if within this step size. i.e. this # * step_size in ms 
Params.low_freq_cutoff = 80;
Params.high_freq_cutoff = 1000;
Params.noise_cutoff = 0.9;

%SET THE PARAMETERS FOR PulseSegmentation

%general Paramseters:
Params.fc = [100:25:750]; %wavelet scales: frequencies examined.
Params.DoGwvlt = [2:3]; %Derivative of Gaussian wavelets examined (2:3)
Params.pWid = round(Params.Fs/250)+1; %pWid:  Approx Pulse Width in points (odd, rounded)
Params.lowIPI = round(Params.Fs/100); %lowIPI: estimate of a very low IPI (even, rounded)
Params.thresh = 4; %thresh:Proportion of smoothed threshold over which pulses are counted. 

%Paramseters for winnowing pulses: 
%first winnow: (returns pulseInfo)
Params.wnwMinAbsVoltage   = 6; %factor times the mean of xempty - only pulses larger than this amplitude are counted as true pulses

%second winnow: (returns pulseInfo2)
Params.IPI = round(Params.Fs/5); %if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse, not within IPI range of another pulse, is likely not a true pulse)
Params.frequency = 700; %if best matched scale is greater than this frequency, then don't include pulse as true pulse
Params.close = round(Params.Fs/50); %if pulse peaks are this close together, only keep the larger pulse (this value should be less than the species-typical IPI)

%SET THE PARAMETERS FOR WinnowSine
Params.max_pulse_pause = 0.070; %max_pulse_pause in seconds, used to winnow apparent sine between pulses
Params.mask_pulses = 'ModelCull2';

%SET THE PARAMETERS FOR FitPulseModel and CullPulses
Params.pulse_model='pulse_model_melanogaster.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
