%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%e.g.
%Params.Fs = 9750;

%note that dealing with github is MUCH easier if you DO NOT modify this
%params file, but rather copy it, modify the copy, use the copy to process
%data, and don't check the copy into git

Params.keep_mediumrare_data = false;
Params.copy_raw_data = true; 
Params.sine_low_freq = 100;
Params.pulse_model='pulse_model_sim5mauwhite.mat';

Params.fc = [100:25:800];             % wavelet scales, in Hertz
Params.pWid = round(Params.Fs/600)+1; % 4*pWid is length of pulse kept, approx pulse width, in ticks (odd, rounded)
Params.frequency = 800;               %if best matched scale is greater than this frequency, do not count as a pulse
Params.minAmplitude  = 7;             %multiple of the mean noise which pulses must exceed