function [ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo,cmhSong,cmhNoise,cmo,cPnts] = Process_Song(xsong,xempty)

%USAGE [ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo] = Process_Song(xsong,xempty)
%OR
%[ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo] = Process_Song(xsong)

addpath(genpath('./chronux'))

fetch_song_params

fprintf('Running multitaper analysis on signal.\n')
[ssf] = sinesongfinder(xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf

if nargin == 1%if user provides only xsong
    xempty = segnspp(ssf,param);
end%if user provides both xsong and xempty

fprintf('Running multitaper analysis on noise.\n')
[noise_ssf] = sinesongfinder(xempty,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval); %returns noise_ssf

%Run lengthfinder3 on ssf and noise_ssf, where:

%freq1 = min value for fundamental frequency of sine song (to determine this value run the compute_spectrogram and plot_computed_spectrogram functions in the spectrogram folder on example data.
%freq2 = max value for fundamental frequency of sine song
fprintf('Finding putative sine and power in signal.\n')
[sine] = lengthfinder4(ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps); %returns sine, which is a structure containing the following fields:

%ssf is structure returned by sinesongfinder, containing results of F test,
%among other things
%freq1 and freq2 define the bottom and top of the frequency band that you
%believe contains the fundamental frequency of true sine song


%start:
%stop:
%length:
%MeanFundFreq:
%MedianFundFreq:
%clips: a cell array containing each sine song clip - each clip is possibly a different length
%fprintf('Finding power in empty chamber.\n')
%[noise_sine] = lengthfinder3(noise_ssf, freq1, freq2);

%Run putativepulse2 on sine and noise_sine, where:

%cutoff_quantile =


fprintf('Finding segments of putative pulse in signal.\n')
[pps] = putativepulse3(ssf,sine,noise_ssf,param.cutoff_quantile,param.range,param.combine_time,param.low_freq_cutoff,param.high_freq_cutoff);  %returns pps, which is a structure containing the following fields:
%start: times at which putative pulse trains start
%stop: times at which putative pulse trains stop
%clips: the actual clips of the putative pulse trains; these are handed off to PulseSegmentation


%Run PulseSegmentation using xsong, xempty, and pps as inputs (and a list of parameters defined above):
if numel(pps.start) > 0
    fprintf('Running wavelet transformation on putative pulse segments.\n')
    [pulseInfo, pulseInfo2, pcndInfo,cmhSong,cmhNoise,cmo,cPnts] = PulseSegmentationv3(xsong, xempty,pps,param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.j,param.k,param.l,param.m,param.Fs);
    
    if pulseInfo2.w0>0;   
    % Grab the pulse information
    numPulses  = numel(pulseInfo2.w0);
    pulseStart = pulseInfo2.w0;
    pulseEnd   = pulseInfo2.w1;
    pulseCenter= pulseInfo2.wc;
    pulseFreq  = pulseInfo2.fcmx;
    
    % Show information for a random pulse, to demonstrate the
    % meaning of values above
%    whichPulse = 1;
%    fprintf('\n\nPulse %d occured between indices %d and %d in the song clip.\n', whichPulse, pulseStart(whichPulse), pulseEnd(whichPulse));
%    fprintf('It was centered at index %d.\n', pulseCenter(whichPulse));
%    fprintf('It''s center frequency was ~%d Hz.\n', pulseFreq(whichPulse));
    
    elseif pulseInfo2.i0 == 0;
    fprintf('no pulses found.\n');    
    end
    
else
    fprintf('No segments of putative pulse detected.\n')
    numPulses = 0;
    pulseInfo = {};
    pulseInfo2 = {};
    pcndInfo = {};
end

% Use results of PulseSegmentation to winnow sine song (remove sine that overlaps pulse)
%Run only if there is any sine 

if sine.num_events == 0;
    winnowed_sine = sine;
elseif pulseInfo2.w0 == 0;
    winnowed_sine = sine;
else
    winnowed_sine = winnow_sine(sine,pulseInfo2,ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
end
