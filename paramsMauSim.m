%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%e.g.
%Params.Fs = 9750;
Params.sines_first = true;
Params.find_sine = true;

Params.sine_low_freq = 80;           % lowest frequency to include as sine, in Hertz
Params.pulse_model='pulse_model_sim5mauwhite.mat';

%Params.fc = [100:25:900];
Params.pWid = round(Params.Fs/571)+1; % approx pulse width, in ticks (odd, rounded)
%Params.minIPI = round(Params.Fs/400); % lowest acceptable IPI, in ticks (even, rounded)

%heuristic pulse cull
%Params.frequency = 700;               %if best matched scale is greater than this frequency, do not count as a pulse
%Params.close = round(Params.Fs/50);   %if pulse peaks are this close together, only keep the larger pulse
