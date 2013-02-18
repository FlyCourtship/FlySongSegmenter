%function Wavelet = PulseSegmenter(cmhSong,cmhNoise,a, b, c, d, e, f, g, h, i, Fs)
function Wavelet = PulseSegmenter(cmhSong,cmhNoise, pWid, minIPI, thresh, Fs)

%========PARAMETERS=================
%segParams.fc = a; % frequencies examined. These will be converted to CWT scales later on.
%segParams.DoGwvlt = b; % Derivative of Gaussian wavelets examined
%segParams.pulsewindow = round(c); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)
%segParams.pWid = c; %pWid: Approx Pulse Width in points (odd, rounded)
%segParams.lowIPI = d; %lowIPI: estimate of a very low IPI (even, rounded)
%segParams.thresh = e; %thresh: Proportion of smoothed threshold over which pulses are counted.
%segParams.wnwMinAbsVoltage = f*mean(abs(xn));
%for 2nd winnow
%segParams.IPI = g; %in samples, if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse (not within IPI range of another pulse) is likely not a true pulse)
%segParams.frequency = h; %if AmpCull.fcmx is greater than this frequency, then don't include pulse
%segParams.close = i; %if pulse peaks are this close together, only keep the larger pulse
%sp = segParams;

%%
%Calculate running maxima for wavelet fits and then smooth
%Perform all operations on noise to make later comparisons meaningful
clear ci
%pWid = sp.pWid;

[sig4Test] = runningExtreme(cmhSong,pWid,'max');
[nDat] = runningExtreme(cmhNoise,pWid,'max');
% sig4Test = sig4Test;
% nDat = nDat;
sig4Test = smooth(sig4Test,(Fs/1000)+pWid);
nDat = smooth(nDat,(Fs/1000)+pWid);
nDat = abs(nDat); %don't want negatives

%%
%Take signal, subtract noise, calculate the mean value of region lowIPI/2
% either side of pulse and take the maximum of this value (to be used as
% threshold). Finally make threshold infinite at start and end to avoid edge
% effects.

%lowIPI = sp.lowIPI;
buff = round(Fs/80); %to avoid edge effects

sig4Test = sig4Test - mean(nDat);
sig4Test = abs(sig4Test);
%smoothF = smooth(circshift(sig4Test,lowIPI/2+1), lowIPI+1);
%smoothB = smooth(circshift(sig4Test, - lowIPI/2-1), lowIPI+1);
smoothF = smooth(circshift(sig4Test,round(minIPI/2)+1), minIPI/2+1);
smoothB = smooth(circshift(sig4Test, - round(minIPI/2)-1), minIPI/2+1);
smthSide = max([smoothF smoothB], [], 2);
smthSide(end - buff-1:end) = inf;
smthSide(1:buff+1) = inf;
smthSide = smthSide*1.1;
smthThresh = smthSide;

% smthMid = smooth(sig4Test,lowIPI*2+1); %smooth sig4Test (will reduce the size of pulse peaks)
% smthMid(smthSide == inf) = inf;
% smthThresh = max([smthMid smthSide*1.1], [], 2);
smthThresh(smthThresh < mean(nDat)) = mean(nDat);
%%
%Perform Threshold Matching
%thresh = sp.thresh;

hiTest = sig4Test; %hiTest will be used for comparison to threshold
hiTest(hiTest - (smthThresh+smthThresh./thresh) <= 0) = 0; %Set threshold based on the maximum of the smoothed region

hiTest(hiTest > 0) = 1; %Take points above threshold
srtIdx = find(diff([0; hiTest]) == 1); %Find start points above thresh
endIdx = find(diff(hiTest) == -1);%Find end points above thresh

%%
%Calculate cPnts by taking the maximum within each region that is above
% threshold.
cPnts = zeros(length(srtIdx),1);
for i = 1:length(srtIdx)
    [~, cPnts(i)] = max(sig4Test(srtIdx(i):endIdx(i)));
    cPnts(i) = cPnts(i) + srtIdx(i) -1;
end

%for debugging:
%figure; plot(xs, 'k'); hold on; plot(cPnts,0.4,'.r'); plot(smthThresh,'b'); plot(sig4Test,'m');


%If cut the above section then add
Wavelet.wc = cPnts;
