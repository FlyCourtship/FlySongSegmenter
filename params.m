%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%e.g.
%Params.Fs = 9750;

%note that dealing with github is MUCH easier if you DO NOT modify this
%params file, but rather copy it, modify the copy, use the copy to process
%data, and don't check the copy into git

Params.keep_mediumrare_data = false;
Params.copy_raw_data = true; 
Params.sine_low_freq = 75;
