%function [cmhSong cmhNoise cmh_dog cmh_sc sc] = WaveletTransform(xs, xn, a, b, c, d, e, f, g, h, i, Fs)
function [cmhSong cmhNoise cmh_dog cmh_sc sc] = WaveletTransform(xs, xn, fc, DoGwvlt, fs)

%pool = exist('matlabpool','file');

%========PARAMETERS=================
%segParams.fc = a; % frequencies examined. These will be converted to CWT scales later on.
%segParams.DoGwvlt = b; % Derivative of Gaussian wavelets examined

%segParams.pWid = c; %pWid: Approx Pulse Width in points (odd, rounded)
%segParams.pulsewindow = round(c); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)
%segParams.lowIPI = d; %lowIPI: estimate of a very low IPI (even, rounded)
%segParams.thresh = e; %thresh: Proportion of smoothed threshold over which pulses are counted.
%segParams.wnwMinAbsVoltage = f*mean(abs(xn));
%%for 2nd winnow
%segParams.IPI = g; %in samples, if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse (not within IPI range of another pulse) is likely not a true pulse)
%segParams.frequency = h; %if AmpCull.fcmx is greater than this frequency, then don't include pulse
%segParams.close = i; %if pulse peaks are this close together, only keep the larger pulse
%sp = segParams;

%% Load the Signals

xs = xs(:);

%% Prepare for CWT
%fprintf('PREPARING FOR CWT.\n');
%ngw = numel(sp.DoGwvlt);
ngw = numel(DoGwvlt);
%fc = sp.fc;
%fs = Fs;

wvlt = cell(1,ngw);

for i = 1:ngw
    %wvlt{i} = ['gaus' num2str(sp.DoGwvlt(i))];
    wvlt{i} = ['gaus' num2str(DoGwvlt(i))];
end

sc = zeros(ngw,numel(fc));

for i = 1:numel(wvlt)
%    fprintf('\tComputing scales for %s.\n',wvlt{i});
    sc(i,:) = scales_for_freqs(fc,1/fs,wvlt{i});
end
%fprintf('DONE.\n');




%% Perform CWT on Signal
%fprintf('PERFORMING CWT SUITE.\n');

cmhSong = single(zeros(1,numel(xs))); % Storage for the maximum mexican hat
                          % wavelet coefficient for each bin.
                          
cmhNoise = single(zeros(1,numel(xn))); % Storage for the maximum mexican hat
                                                              % wavelet coefficient for each bin in noise signal.

cmh_dog = int8(zeros(1,length(xs))); % Storage for the order of the
                          % D.o.G. wavelet for which the highest
                          % coefficient occured.

cmh_sc = int8(zeros(1,length(xs))); % Storage for the scale at which the
                          % highest mexican hat coefficient occured.
                    
% if pool ~=0;%if multicore capability, then use
% parfor i= 1:numel(wvlt)
% fprintf('\t%s\n',wvlt{i});
% fprintf('\t\t...on Signal\n');
% Cs(:,:,i) = cwt(xs,sc(i,:),wvlt{i}); %wavelet transformation on signal for that scale and that wavelet
% fprintf('\t%s\n',wvlt{i});
% fprintf('\t\t...on Noise\n');
% Cn(:,:,i) = cwt(xn,sc(i,:),wvlt{i}); %wavelet transformation on noise for that scale and that wavelet
% end
% else
for i= 1:numel(wvlt)
    %fprintf('\t%s\n',wvlt{i});
    %fprintf('\t\t...on Signal\n');
    for j = 1:size(sc,2)
        temp = single(abs(cwt(xs,sc(i,j),wvlt{i})));
        cmh_sc(temp>cmhSong) = j;
        cmh_dog(temp>cmhSong) = i;
        cmhSong(temp>cmhSong) = temp(temp>cmhSong);
        clear temp;
    end
    %fprintf('\t\t...on Noise\n');
    for j = 1:size(sc,2)
    cmhNoise = max(abs([cmhNoise; single(cwt(xn,sc(i,j),wvlt{i}))])); %wavelet transformation on noise for that scale and that wavelet
    end
end
%now we have cmh for the signal and cmh_noise for the noise
