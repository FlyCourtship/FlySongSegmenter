%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%e.g.
%Params.Fs = 9750;

Params.keep_mediumrare_data = false;   % Sines.MultiTaper.A, Pulses.cmhSong/cmhNoise/cmh_dog/cmh_sc are BIG
