%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%e.g.
Params.Fs = 10000;

%note that dealing with github is MUCH easier if you DO NOT modify this
%params file, but rather copy it, modify the copy, use the copy to process
%data, and don't check the copy into git

Params.sines_first = false;
%Params.sine_low_freq = 70;
% sine song:  multi-taper
Params.NW = 40;                       % time-bandwidth product for tapers
Params.K = 75;                        % numver independent tapers to average over, must be < 2*NW
Params.dT = 0.1;                      % FFT window length, in seconds
Params.dS = 0.01;                     % FFT window step size, in seconds
Params.pval = 0.1;                   % criterion for F-test
Params.fwindow = [50 500];       % frequency range to analyze, in Hertz

