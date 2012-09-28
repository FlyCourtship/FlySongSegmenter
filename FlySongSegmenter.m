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
      num2str(param.Fs) ' in ' params_path '.  Proceeding with ' num2str(varargin{1})]);
  param.Fs=varargin{1};
end

disp(['Song length is ' num2str(length(xsong)/param.Fs/60,3) ' minutes.']);
data.d = xsong;
data.fs = param.Fs;

fprintf('Finding noise floor in recording.\n')
if isempty(xempty) %if user provides only xsong
  xempty=xsong(1:min(end,1e6));
end
%if length(xsong) <1.1e6
%  song = xsong;
%else
%  song = xsong(1:1e6);
%end
tmp = MultiTaperFTest(xempty,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);
noise = EstimateNoise(tmp,param,param.low_freq_cutoff,param.high_freq_cutoff);

%Run PulseSegmentationv4 using xsong, xempty, and pps as inputs (and a list of parameters defined above):
fprintf('Running wavelet transformation.\n')
    
%[pcndInfo, pulseInfo, pulseInfo2, cmhSong] = ...
[Pulses.FromWavelet, Pulses.CulledByAmplitude, Pulses.CulledByIPIFrequency, cmhSong] = ...
    PulseSegmenter(xsong,noise.d,[],param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);
    
if param.find_sine == 1

  if ismember('x',fieldnames(Pulses.CulledByAmplitude))
          
    % Mask putative pulses in xsong. Use pulseInfo pulses.
    pm_xsong = MaskPulses(xsong,Pulses.CulledByAmplitude);
    fprintf('Running multitaper analysis on pulse-masked signal.\n')
    %pm_ssf = MultiTaperFTest(pm_xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);
    Sines.FromMultiTaper = ...
        MultiTaperFTest(pm_xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);
        
    fprintf('Finding sine in pulse-masked signal.\n')
    %pm_sine = ...
    [Sines.MergedInTimeHarmonics Sines.CulledByLengthFrequency] = SineSegmenter(Sines.FromMultiTaper,...
        param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps);
        
    % Use results of PulseSegmentation to winnow sine song (remove sine that overlaps pulse)
    %Run only if there is any sine
        
    if Sines.MergedInTimeHarmonics.num_events == 0;
      Sines.CulledFromPulses = Sines.CulledByLengthFrequency;
      Sines.CulledFromPulses.events = {};
      Sines.CulledFromPulses.eventTimes = {};
      Sines.CulledFromPulses.power = {};
      Sines.CulledFromPulses.powerMat = [];
    elseif Pulses.CulledByIPIFrequency.w0 == 0;
      Sines.CulledFromPulses = Sines.CulledByLengthFrequency;
      Sines.CulledFromPulses.events = {};
      Sines.CulledFromPulses.eventTimes = {};
      Sines.CulledFromPulses.power = {};
      Sines.CulledFromPulses.powerMat = [];
    else
      if ismember('x',fieldnames(Pulses.CulledByIPIFrequency))
        Sines.CulledFromPulses = ...
            WinnowSine(Sines.CulledByLengthFrequency,Pulses.CulledByIPIFrequency,Sines.FromMultiTaper,...
              param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
      else
        Sines.CulledFromPulses = ...
            WinnowSine(Sines.CulledByLengthFrequency,Pulses.CulledByIPIFrequency,Sines.FromMultiTaper,...
              param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq);
      end
    end
  else
    Pulses.CulledByIPIFrequency = {};
        
    fprintf('Running multitaper analysis on signal.\n')
    Sines.FromMultiTaper = ...
        MultiTaperFTest(xsong,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow,1);
        
    fprintf('Finding sine in signal.\n')
    [Sines.MergedInTimeHarmonics Sines.CulledByLengthFrequency] = ...
        SineSegmenter(ssf,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent,param.discard_less_n_steps);

    Sines.CulledFromPulses = Sines.CulledByLengthFrequency;
  end
else
    Sines.CulledFromPulses = {};
end

if(exist('cpm','var'))
  fprintf('Culling pulses with likelihood model.\n')
  [pulse_model,Lik_pulse]=FitPulseModel(cpm,Pulses.CulledByAmplitude.x);
  [pulse_model2,Lik_pulse2]=FitPulseModel(cpm,Pulses.CulledByIPIFrequency.x);
  Pulses.CulledByModel = CullPulses(Pulses.CulledByAmplitude,Lik_pulse.LLR_fh,[0 max(Lik_pulse.LLR_fh) + 1]);
  Pulses.CulledByModel2 = CullPulses(Pulses.CulledByIPIFrequency,Lik_pulse2.LLR_fh,[0 max(Lik_pulse2.LLR_fh) + 1]);
end

%clear ssf pm_ssf pm_sine

check_close_pool(poolavail,isOpen);

tstop=toc(tstart);
disp(['Run time was ' num2str(tstop/60,3) ' minutes.']);


% step 2: put this into .m file to source in analysis code, and return Pulses & Sines
pcndInfo          = Pulses.FromWavelet;
pulseInfo         = Pulses.CulledByAmplitude;
pulseInfo2        = Pulses.CulledByIPIFrequency;
culled_pulseInfo  = Pulses.CulledByModel;
culled_pulseInfo2 = Pulses.CulledByModel2;

pm_ssf        = Sines.FromMultiTaper;
%             = Sines.MergedInTimeHarmonics;
pm_sine       = Sines.CulledByLengthFrequency;
winnowed_sine = Sines.CulledFromPulses;
