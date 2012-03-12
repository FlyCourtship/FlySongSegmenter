function [data, winnowed_sine, pcndInfo, pulseInfo, pulseInfo2] = Process_Song_pulseonly(xsong,xempty)

%USAGE [data, winnowed_sine, pulseInfo2, pulseInfo] = Process_Song_pulseonly(xsong,xempty)
%OR
%[data, winnowed_sine, pulseInfo2, pulseInfo] = Process_Song_pulseonly(xsong)

%This code modified for analyzing song of species with mel-like pulses and
%no sine song. 

addpath(genpath('./chronux'))

[poolavail,isOpen] = check_open_pool;

fetch_song_params

fprintf('Running multitaper analysis on signal.\n')
[ssf] = sinesongfinder(xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,1); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
data.d = ssf.d;
data.fs = ssf.fs;

if nargin == 1 %if user provides only xsong
    xempty = segnspp(ssf,param);
end %if user provides both xsong and xempty

fprintf('Running multitaper analysis on noise.\n')
[noise_ssf] = sinesongfinder(xempty,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,1); %returns noise_ssf

%Run lengthfinder4 on ssf and noise_ssf, where:
fprintf('Finding putative sine and power in signal.\n')
[sine] = lengthfinder4(ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps); %returns sine, which is a structure containing the following fields:

%Run putativepulse2 on sine and noise_sine, where:
fprintf('Finding segments of putative pulse in signal.\n')
[pps] = putativepulse3(ssf,sine,noise_ssf,param.cutoff_quantile,param.range,param.combine_time,param.low_freq_cutoff,param.high_freq_cutoff);  %returns pps, which is a structure containing the following fields:

clear ssf noise_ssf

%Run PulseSegmentationv3 using xsong, xempty, and pps as inputs (and a list of parameters defined above):
if numel(pps.start) > 0
    fprintf('Running wavelet transformation on putative pulse segments.\n')
    [pcndInfo, pulseInfo, pulseInfo2] = PulseSegmentationv3(xsong,xempty,pps,param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.j,param.k,param.Fs);
    
    clear pps
%     if size(pulseInfo2.x,2) > 0
%         
%         % Mask putative pulses in xsong. Use pulseInfo pulses.
%         pm_xsong = pulse_mask(xsong,pulseInfo);
%         fprintf('Running multitaper analysis on pulse-masked signal.\n')
%         pm_ssf = sinesongfinder(pm_xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,1); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
%         
%         fprintf('Finding putative sine in pulse-masked signal.\n')
%         pm_sine = lengthfinder4(pm_ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps); %returns sine, which is a structure containing the following fields:
%         
%         % Use results of PulseSegmentation to winnow sine song (remove sine that overlaps pulse)
%         %Run only if there is any sine
%         
%         if sine.num_events == 0;
%             winnowed_sine = pm_sine;
%         elseif pulseInfo2.w0 == 0;
%             winnowed_sine = pm_sine;
%         else
%             winnowed_sine = winnow_sine(pm_sine,pulseInfo2,pm_ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
%         end
%     else
%         pulseInfo2 = {};
%         winnowed_sine = sine;
%     end
else
    fprintf('No segments of putative pulse detected.\n')
    pcndInfo = {};
    pulseInfo = {};
    pulseInfo2 = {};
    
end
winnowed_sine = {};
clear pm_ssf pm_sine
check_close_pool(poolavail,isOpen);
