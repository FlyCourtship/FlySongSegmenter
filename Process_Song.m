function [data, winnowed_sine, pulseInfo, pulseInfo2, pcndInfo] = Process_Song(xsong,xempty,params_path)

%USAGE [data, winnowed_sine, pulseInfo, pulseInfo2, pcndInfo] = Process_Song(xsong,[],'./params.m')
%This is the core program for analyzing courtship song

tstart=tic;

if(~isdeployed)  addpath(genpath('./chronux'));  end

if nargin < 3
    params_path = '';
end
fetch_song_params

disp(['Song length is ' num2str(length(xsong)/param.Fs/60,3) ' minutes.']);

fprintf('Finding noise floor in recording.\n')
if length(xsong) <1.1e6
    song = xsong;
else
    song =  xsong(1:1e6);
end

[ssf] = sinesongfinder(song,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow,1); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf

data.d = xsong;
data.fs = ssf.fs;
fprintf('Finding noise.\n')
if isempty(xempty) %if user provides only xsong
    noise = findnoise(ssf,param,param.low_freq_cutoff,param.high_freq_cutoff);
end %if user provides both xsong and xempty

%Run PulseSegmentationv4 using xsong, xempty, and pps as inputs (and a list of parameters defined above):
    fprintf('Running wavelet transformation.\n')
    
      [pcndInfo, pulseInfo, pulseInfo2, cmhSong] = PulseSegmentationv4(xsong,noise.d,[],param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);
    
    if param.find_sine == 1

        if ismember('x',fieldnames(pulseInfo))
            
            % Mask putative pulses in xsong. Use pulseInfo pulses.
            pm_xsong = pulse_mask(xsong,pulseInfo);
            fprintf('Running multitaper analysis on pulse-masked signal.\n')
            pm_ssf = sinesongfinderV2(pm_xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow,1); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
            
            fprintf('Finding sine in pulse-masked signal.\n')
            pm_sine = findsine(pm_ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps); %returns sine, which is a structure containing the following fields:
            
            % Use results of PulseSegmentation to winnow sine song (remove sine that overlaps pulse)
            %Run only if there is any sine
            
            if pm_sine.num_events == 0;
                winnowed_sine = pm_sine;
                winnowed_sine.events = {};
                winnowed_sine.eventTimes = {};
                winnowed_sine.power = {};
                winnowed_sine.powerMat = [];
            elseif pulseInfo2.w0 == 0;
                winnowed_sine = pm_sine;
                winnowed_sine.events = {};
                winnowed_sine.eventTimes = {};
                winnowed_sine.power = {};
                winnowed_sine.powerMat = [];
            else
                if ismember('x',fieldnames(pulseInfo2))
                    winnowed_sine = winnow_sine2(pm_sine,pulseInfo2,pm_ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
                else
                    winnowed_sine = winnow_sine2(pm_sine,pulseInfo,pm_ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
                end
            end
        else
            pulseInfo2 = {};
            
            fprintf('Running multitaper analysis on signal.\n')
            ssf = sinesongfinderV2(xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow,1); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
            
            fprintf('Finding sine in signal.\n')
            pm_sine = findsine(ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps); %returns sine, which is a structure containing the following fields:
 
            winnowed_sine = pm_sine;
        end
    else
        winnowed_sine = {};
    end



clear ssf pm_ssf pm_sine

tstop=toc(tstart);
disp(['Run time was ' num2str(tstop/60,3) ' minutes.']);
