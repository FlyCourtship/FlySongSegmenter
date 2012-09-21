function [data, winnowed_sine, pulseInfo, pulseInfo2, pcndInfo, Lik_pulse, pulse_model, Lik_pulse2, pulse_model2] = ...
    FlySongSegmenter(xsong,xempty,params_path,varargin)

%USAGE [data, winnowed_sine, pulseInfo, pulseInfo2, pcndInfo] = FlySongSegmenter(xsong,[],'./params.m')
%This is the core program for analyzing courtship song
%the sole varargin is the sampling rate passed in from FlySongSegmenterDAQ to cross check with params

tstart=tic;

[poolavail,isOpen] = check_open_pool;

if(~isdeployed)
  addpath(genpath('./chronux'));
  addpath('./order');
  addpath('./padcat2');
end

if nargin < 3
  params_path = '';
end
FetchParams;

if(varargin{1}~=param.Fs)
  disp(['WARNING:  sampling rate is specified as ' num2str(varargin{1}) ' in the .daq file and ' ...
      num2str(param.Fs) ' in ' params_path]);
end

disp(['Song length is ' num2str(length(xsong)/param.Fs/60,3) ' minutes.']);

fprintf('Finding noise floor in recording.\n')
if length(xsong) <1.1e6
  song = xsong;
else
  song = xsong(1:1e6);
end

[ssf] = MultiTaperFTest(song,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);

data.d = xsong;
data.fs = ssf.fs;
%fprintf('Finding noise.\n')
if isempty(xempty) %if user provides only xsong
  noise = EstimateNoise(ssf,param,param.low_freq_cutoff,param.high_freq_cutoff);
end

%Run PulseSegmentationv4 using xsong, xempty, and pps as inputs (and a list of parameters defined above):
fprintf('Running wavelet transformation.\n')
    
[pcndInfo, pulseInfo, pulseInfo2, cmhSong] = ...
    PulseSegmenter(xsong,noise.d,[],param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);
    
if param.find_sine == 1

  if ismember('x',fieldnames(pulseInfo))
          
    % Mask putative pulses in xsong. Use pulseInfo pulses.
    pm_xsong = MaskPulses(xsong,pulseInfo);
    fprintf('Running multitaper analysis on pulse-masked signal.\n')
    pm_ssf = MultiTaperFTest(pm_xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);
        
    fprintf('Finding sine in pulse-masked signal.\n')
    pm_sine = ...
        SineSegmenter(pm_ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps);
        
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
        winnowed_sine = ...
            WinnowSine(pm_sine,pulseInfo2,pm_ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
      else
        winnowed_sine = ...
            WinnowSine(pm_sine,pulseInfo,pm_ssf,param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
      end
    end
  else
    pulseInfo2 = {};
        
    fprintf('Running multitaper analysis on signal.\n')
    ssf = MultiTaperFTest(xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow,1);
        
    fprintf('Finding sine in signal.\n')
    pm_sine = ...
        SineSegmenter(ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps);

    winnowed_sine = pm_sine;
  end
else
    winnowed_sine = {};
end

if(exist('cpm','var'))
  fprintf('Culling pulses with likelihood model.\n')
  [pulse_model,Lik_pulse]=FitPulseModel(cpm,pulseInfo.x);
  [pulse_model2,Lik_pulse2]=FitPulseModel(cpm,pulseInfo2.x);
  culled_pulseInfo = CullPulses(pulseInfo,Lik_pulse.LLR_fh,[0 max(Lik_pulse.LLR_fh) + 1]);
  culled_pulseInfo2 = CullPulses(pulseInfo2,Lik_pulse2.LLR_fh,[0 max(Lik_pulse2.LLR_fh) + 1]);
end


clear ssf pm_ssf pm_sine

check_close_pool(poolavail,isOpen);

tstop=toc(tstart);
disp(['Run time was ' num2str(tstop/60,3) ' minutes.']);
