function [data, Sines, Pulses] = ...
    FlySongSegmenter(xsong,xempty,params_path,varargin)

%USAGE [data, Sines, Pulses] = FlySongSegmenter(xsong,[],'./params.m',...)
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
data.d = xsong-repmat(mean(xsong),size(xsong,1),1);
data.fs = param.Fs;

fprintf('Finding noise floor.\n')
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
[Pulses.cmhSong Pulses.cmhNoise Pulses.cmh_dog Pulses.cmh_sc Pulses.sc] = WaveletTransform(xsong,noise.d,...
    param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);

fprintf('Segmenting pulses.\n')
Pulses.Wavelet = PulseSegmenter(Pulses.cmhSong,Pulses.cmhNoise,...
    param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);

fprintf('Culling pulses heuristically.\n')
[Pulses.Wavelet Pulses.AmpCull Pulses.IPICull] = ...
    CullPulses(Pulses.Wavelet,Pulses.cmh_dog,Pulses.cmh_sc,Pulses.sc,xsong,noise.d,...
    param.a,param.b,param.c,param.d,param.e,param.f,param.g,param.h,param.i,param.Fs);
    
if(exist('cpm','var'))
  fprintf('Culling pulses with likelihood model.\n')
  [Pulses.pulse_model,Pulses.Lik_pulse]=FitPulseModel(cpm,Pulses.AmpCull.x);
  [Pulses.pulse_model2,Pulses.Lik_pulse2]=FitPulseModel(cpm,Pulses.IPICull.x);
  Pulses.ModelCull=ModelCullPulses(Pulses.AmpCull,Pulses.Lik_pulse.LLR_fh,[0 max(Pulses.Lik_pulse.LLR_fh)+1]);
  Pulses.ModelCull2=ModelCullPulses(Pulses.IPICull,Pulses.Lik_pulse2.LLR_fh,[0 max(Pulses.Lik_pulse2.LLR_fh)+1]);
end

if param.find_sine == 1
        
  if ismember('x',fieldnames(Pulses.(mask_pulses)))
    fprintf('Masking pulses.\n')
    tmp = MaskPulses(xsong,Pulses.(mask_pulses));
  else
    tmp = xsong;
  end

  fprintf('Running multitaper analysis.\n')
  Sines.MultiTaper = ...
      MultiTaperFTest(tmp,param.Fs,param.NW,param.K,param.dT,param.dS,param.pval,param.fwindow);
      
  fprintf('Segmenting sine song.\n')
  Sines.TimeHarmonicMerge = ...
      SineSegmenter(Sines.MultiTaper,param.sine_low_freq,param.sine_high_freq,param.sine_range_percent);

  fprintf('Winnowing sine song.\n')
  [Sines.PulsesCull Sines.LengthCull] = ...
      WinnowSine(Sines.TimeHarmonicMerge,Pulses.(mask_pulses),Sines.MultiTaper,...
        param.max_pulse_pause,param.sine_low_freq,param.sine_high_freq,param.discard_less_n_steps);

%  end
else
  Sines.MultiTaper = {};
  Sines.TimeHarmonicMerge= {};
  Sines.PulsesCull = {};
  Sines.LengthCull = {};
end

%clear ssf pm_ssf pm_sine

check_close_pool(poolavail,isOpen);

tstop=toc(tstart);
disp(['Run time was ' num2str(tstop/60,3) ' minutes.']);
