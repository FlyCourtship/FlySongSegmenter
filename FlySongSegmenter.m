function [Data, Sines, Pulses, Params] = ...
    FlySongSegmenter(xsong,xempty,params_path,varargin)

%This is the core program for analyzing courtship song
%  xsong is the song to be analyzed
%  xempty is a recording with no song from which noise characteristics are estimated.
%    to estimate noise from xsong instead, specifiy xempty as []
%  params_path is the full path to the custom parameters file.  if specified as [], ./params.m is used
%  the sole varargin is the sampling rate passed in from FlySongSegmenterDAQ to cross check with params

tstart=tic;

%[poolavail,isOpen] = check_open_pool;

if(~isdeployed)
    addpath(genpath('./chronux'));
    addpath('./order');
    addpath('./padcat2');
end

if nargin < 3
    params_path = [];
end
FetchParams;

if((nargin>3) & (varargin{1}~=Params.Fs))
    disp(['WARNING:  sampling rate is specified as ' num2str(varargin{1}) ' in the .daq file and ' ...
        num2str(Params.Fs) ' in ' params_path '.  Proceeding with ' num2str(varargin{1})]);
    Params.Fs=varargin{1};
end

disp(['Song length is ' num2str(length(xsong)/Params.Fs/60,3) ' minutes.']);
Data.d = xsong;
Data.fs = Params.Fs;


if Params.sines_first && Params.find_sine
   fprintf('Running multitaper analysis #1.\n')
    % multi taper estimate sine
   Sines.MultiTaper = ...
       MultiTaperFTest(Data.d, Params.Fs, Params.NW, Params.K, Params.dT, Params.dS, Params.pval, Params.fwindow);
   tmp = Sines.MultiTaper;
   
   Sines.TimeHarmonicMerge = ...
       SineSegmenter(Data.d, Sines.MultiTaper, Params.Fs, Params.dT, Params.dS, ...
       Params.sine_low_freq, Params.sine_high_freq, Params.sine_range_percent);
   
   % mask sine in xsong
   xsong = MaskSines(Data.d,Sines.TimeHarmonicMerge);
else
    if isempty(xempty) %if user provides only xsong
        xempty=xsong(1:min(end,1e6));
    end
    tmp = MultiTaperFTest(xempty, Params.Fs, Params.NW, Params.K, Params.dT, Params.dS, Params.pval, Params.fwindow);
    
end
fprintf('Finding noise floor.\n')
noise = EstimateNoise(xsong, tmp, Params, Params.low_freq_cutoff, Params.high_freq_cutoff);



fprintf('Running wavelet transformation.\n')
[Pulses.cmhSong  Pulses.cmhNoise  Pulses.cmh_dog  Pulses.cmh_sc  Pulses.sc] = ...
    WaveletTransform(xsong, noise.d, Params.fc, Params.DoGwvlt, Params.Fs);

fprintf('Segmenting pulses.\n')
Pulses.Wavelet = PulseSegmenter(Pulses.cmhSong, Pulses.cmhNoise,...
    Params.pWid, Params.minIPI, Params.thresh, Params.Fs);

fprintf('Culling pulses heuristically.\n')
[Pulses.Wavelet  Pulses.AmpCull  Pulses.IPICull] = ...
    CullPulses(Pulses.Wavelet, Pulses.cmh_dog, Pulses.cmh_sc, Pulses.sc, xsong, noise.d,...
    Params.fc, Params.pWid, Params.minAmplitude, Params.maxIPI, Params.frequency, Params.close);

if(exist('cpm','var'))
    fprintf('Culling pulses with likelihood model.\n')
    [Pulses.pulse_model  Pulses.Lik_pulse] = FitPulseModel(cpm,Pulses.AmpCull.x,Params.raw_model);
    [Pulses.pulse_model2  Pulses.Lik_pulse2] = FitPulseModel(cpm,Pulses.IPICull.x,Params.raw_model);
    Pulses.ModelCull = ModelCullPulses(Pulses.AmpCull, Pulses.Lik_pulse.LLR_fh, [0 max(Pulses.Lik_pulse.LLR_fh)+1]);
    Pulses.ModelCull2 = ModelCullPulses(Pulses.IPICull, Pulses.Lik_pulse2.LLR_fh, [0 max(Pulses.Lik_pulse2.LLR_fh)+1]);
    Pulses.OldPulseModel = cpm;
end

if Params.find_sine
    
    if ~isempty(Pulses.(Params.mask_pulses))
        fprintf('Masking pulses.\n')
        tmp = MaskPulses(Data.d,Pulses.(Params.mask_pulses));
    else
        tmp = Data.d;
    end
    
    fprintf('Running multitaper analysis.\n')
    Sines.MultiTaper = ...
        MultiTaperFTest(tmp, Params.Fs, Params.NW, Params.K, Params.dT, Params.dS, Params.pval, Params.fwindow);
    
    fprintf('Segmenting sine song.\n')
    Sines.TimeHarmonicMerge = ...
        SineSegmenter(tmp, Sines.MultiTaper, Params.Fs, Params.dT, Params.dS, ...
        Params.sine_low_freq, Params.sine_high_freq, Params.sine_range_percent);
    
    fprintf('Winnowing sine song.\n')
    [Sines.PulsesCull Sines.LengthCull] = ...
        WinnowSine(tmp, Sines.TimeHarmonicMerge, Pulses.(Params.mask_pulses), Sines.MultiTaper,...
        Params.Fs, Params.dS, ...
        Params.max_pulse_pause, Params.sine_low_freq, Params.sine_high_freq, Params.discard_less_sec);
    
else
    Sines.MultiTaper = {};
    Sines.TimeHarmonicMerge= {};
    Sines.PulsesCull = {};
    Sines.LengthCull = {};
end

if ~Params.keep_mediumrare_data
    Sines.MultiTaper.A=[];
    Pulses.cmhSong=[];
    Pulses.cmhNoise=[];
    Pulses.cmh_dog=[];
    Pulses.cmh_sc=[];
    
    Sines.TimeHarmonicMerge.clips=[];
    Sines.PulsesCull.clips=[];
    Sines.LengthCull.clips=[];
    Pulses.Wavelet.x=[];
    Pulses.AmpCull.x=[];
    Pulses.IPICull.x=[];
    Pulses.ModelCull.x=[];
    Pulses.ModelCull2.x=[];
    Pulses.pulse_model.allZ2oldfhM=[];
    Pulses.pulse_model.allZ2oldshM=[];
    Pulses.pulse_model2.allZ2oldfhM=[];
    Pulses.pulse_model2.allZ2oldshM=[];
end

if ~Params.copy_raw_data
    Data.d = [];
end

%check_close_pool(poolavail,isOpen);

tstop=toc(tstart);
disp(['Run time was ' num2str(tstop/60,3) ' minutes.']);
