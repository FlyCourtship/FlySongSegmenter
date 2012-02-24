function [pcndInfo, pulseInfo, pulseInfo2, cmhSong] = PulseSegmentationv3(xsong, xempty, pps, a, b, c, d, e, f, g, h, i, Fs)

pool = exist('matlabpool','file');

%========PARAMETERS=================
segParams.fc = a; % frequencies examined. These will be converted to CWT scales later on.

segParams.DoGwvlt = b;  % Derivative of Gaussian wavelets examined

segParams.pWid = c; %pWid: Approx Pulse Width in points (odd, rounded)

segParams.pulsewindow = round(c); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)

segParams.lowIPI = d; %lowIPI: estimate of a very low IPI (even, rounded)

segParams.thresh = e; %thresh: Proportion of smoothed threshold over which pulses are counted.

xn = xempty;
noise = f*mean(abs(xn));                         
segParams.wnwMinAbsVoltage = noise; 

%for 2nd winnow
segParams.IPI = g; %in samples, if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse (not within IPI range of another pulse) is likely not a true pulse)

segParams.frequency = h; %if pulseInfo.fcmx is greater than this frequency, then don't include pulse

segParams.close = i; %if pulse peaks are this close together, only keep the larger pulse

sp = segParams;

%% Load the Signals

xs = xsong; %no downsampling
xs  = xs(:);
xn = xempty;

%% Prepare for CWT
fprintf('PREPARING FOR CWT.\n');
ngw = numel(sp.DoGwvlt);
fc  = sp.fc;
fs  = Fs;

wvlt = cell(1,ngw);
% wvlt{1} = 'morl'; %kept the morlet here in case it ends up being useful later

for i = 1:ngw
    wvlt{i} = ['gaus' num2str(sp.DoGwvlt(i))];
end

sc = zeros(ngw,numel(fc));

for i = 1:numel(wvlt)
    fprintf('\tComputing scales for %s.\n',wvlt{i});
    sc(i,:) = scales_for_freqs(fc,1/fs,wvlt{i});
end
fprintf('DONE.\n');




%% Perform CWT on Signal
fprintf('PERFORMING CWT SUITE.\n');

% cmo = zeros(1,numel(xs));   % Storage for the maximum morlet wavelet
                                                % coefficient for each bin.

cmh = zeros(1,numel(xs));      % Storage for the maximum mexican hat
                          % wavelet coefficient for each bin.
                          
cmh_noise = zeros(1,numel(xn));     % Storage for the maximum mexican hat
                                                              % wavelet coefficient for each bin in noise signal.

% cmo_sc = cmo;             % Storage for the scale at which the
                                        % highest coefficient occured for each bin.

cmh_dog = zeros(1,numel(xs));            % Storage for the order of the
                          % D.o.G. wavelet for which the highest
                          % coefficient occured.

cmh_sc = zeros(1,numel(xs));             % Storage for the scale at which the
                          % highest mexican hat coefficient occured.
                          
Cs = zeros(length(fc),length(xs),numel(wvlt));Cn = zeros(length(fc),length(xn),numel(wvlt));
% if pool ~=0;%if multicore capability, then use
%     parfor i= 1:numel(wvlt)
%         fprintf('\t%s\n',wvlt{i});
%         fprintf('\t\t...on Signal\n');
%         Cs(:,:,i) = cwt(xs,sc(i,:),wvlt{i}); %wavelet transformation on signal for that scale and that wavelet
%         fprintf('\t%s\n',wvlt{i});
%         fprintf('\t\t...on Noise\n');
%         Cn(:,:,i) = cwt(xn,sc(i,:),wvlt{i}); %wavelet transformation on noise for that scale and that wavelet
%     end
% else
    for i= 1:numel(wvlt)
        fprintf('\t%s\n',wvlt{i});
        fprintf('\t\t...on Signal\n');
        Cs(:,:,i) = cwt(xs,sc(i,:),wvlt{i}); %wavelet transformation on signal for that scale and that wavelet
        fprintf('\t\t...on Noise\n');
        Cn(:,:,i) = cwt(xn,sc(i,:),wvlt{i}); %wavelet transformation on noise for that scale and that wavelet
%         fprintf('\t\tComputing power.\n');
%         Ps = Cs(:,:,i).*conj(Cs(:,:,i));
%         Pn = Cn(:,:,i).*conj(Cn(:,:,i));
    end
% end




for i = 1:numel(wvlt)
    fprintf('\t\tFinding the maximum coefficient for each bin.\n');
    [cs,ci] = max(abs(Cs(:,:,i)));    
    [cn,~] = max(abs(Cn(:,:,i)));    
    if (isequal(wvlt{i},'morl'))
        cmo = cs;
        cmo_sc = ci;  %best cmo scale
    else %if a DoG wavelet
        cmh1 = cs;
        cmh2 = cn;
        best_sc = ci;
%         best_sc_noise = cin;
        cmh1gtcmh = cmh1>cmh; % indices where current coefficient
                              % was greater than the running max.
                              
        cmh2gtcmh_noise = cmh2>cmh_noise; % indices where current coefficient
                              % was greater than the running max.

        % Update the max scale for each bin (just for the signal).
        cmh_sc = cmh1gtcmh.*best_sc + ~cmh1gtcmh.*cmh_sc; 
        
        % Update the max coefficient for each bin.
        cmh = cmh1.*cmh1gtcmh+cmh.*~cmh1gtcmh; 
        cmh_noise = cmh2.*cmh2gtcmh_noise+cmh_noise.*~cmh2gtcmh_noise; 
        
        % Update the max DoG order for each bin (just for the signal).
        cmh_dog = (i-1).*cmh1gtcmh+cmh_dog.*~cmh1gtcmh; 
        
    end
end

%now we have cmh and cmo for the signal and cmh_noise for the noise
cmhSong = cmh;
cmhNoise = cmh_noise;

%% 
%Calculate running maxima for wavelet fits and then smooth
%Perform all operations on noise to make later comparisons meaningful

pWid = sp.pWid;

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

lowIPI = sp.lowIPI;
buff = round(Fs/80); %to avoid edge effects

sig4Test = sig4Test - mean(nDat);
sig4Test = abs(sig4Test);
smoothF = smooth(circshift(sig4Test,lowIPI/2+1), lowIPI+1); 
smoothB = smooth(circshift(sig4Test, - lowIPI/2-1), lowIPI+1);
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
thresh = sp.thresh;

hiTest = sig4Test; %hiTest will be used for comparison to threshold
hiTest(hiTest - (smthThresh+smthThresh./thresh) <= 0) = 0; %Set threshold based on the maximum of the smoothed region 

hiTest(hiTest > 0) = 1; %Take points above threshold
srtIdx = find(diff([0; hiTest]) == 1); %Find start points above thresh
endIdx = find(diff(hiTest) == -1);%Find end points above thresh

%% 
%Calculate cPnts by taking the maximum within each region that is above
% threshold. 

for i = 1:length(srtIdx)
[~, cPnts(i)] = max(sig4Test(srtIdx(i):endIdx(i)));
cPnts(i) = cPnts(i) + srtIdx(i) -1;
end

%for debugging:
%figure; plot(xs, 'k'); hold on; plot(cPnts,0.4,'.r'); plot(smthThresh,'b'); plot(sig4Test,'m');
%% Use output of putativepulse2 (pps) to identify regions of song that may contain pulses (and do not contain sines)

tic;
for i=1:numel(pps.clips); %for each putative pulse segment
    a = pps.clips(i);
    b = size(a{1},1);
    pps.stop2(1,i) = round(pps.start(i)*Fs) + round(b) - 1;
end
putpul = struct('i0',round(pps.start*Fs), 'i1', pps.stop2);
number = numel(pps.start);

%cPnts has all of the times where pulse peaks occur

A = [];
A = length(cmhSong);
B=[];
B = length(double(putpul.i1));
if putpul.i0(1) < 1;
    putpul.i0(1) = 1;
end
if putpul.i1(B) > A;
    putpul.i1(B) = A;
end

fprintf('EXTRACTING CANDIDATE PULSES.\n');

% pulses = {};
% pulse_start_times = [];
% pulse_lengths = [];

n = 1;
for i=1:number; %for each putative pulse segment
    if double(putpul.i0(i)) == double(putpul.i1(i));
        continue
    end    
    
    start=[];
    stop=[];
    aa=[];
    ii=[];
    
    start = putpul.i0(i); %putative pulse segmenet start time
    stop = putpul.i1(i); %putative pulse segmenet stop time
    aa = find(cPnts < stop & cPnts > start); %find those pulse peaks in this segment
    ii = cPnts(aa);
    s = length(ii); %the number of pulses in this segment
    
    pulse_peaks(n:n+s-1) = ii; %put the pulse peak times in pulse_peaks
    n = n + s;
end
     
zz = zeros(1,length(pulse_peaks));
pcndInfo = struct('wc',double(pulse_peaks),...
           'dog',zz,'scmx',zz,'fcmx',zz,'w0',zz,'w1',zz);



if pcndInfo.wc==0;
    zz = zeros(1,10);
    pulseInfo.w0 = zz;
    pulseInfo2.w0=zz;
    return
end
%%
%FIRST WINNOW
%Collecting pulses in pulseInfo (removing those below the noise threshold):

indPulse = 0*xs;
np = numel(pcndInfo.wc); %the number of pulses total

nOk = 0;

% pcndInfo contains all pulse candidates. If a pulse makes it past the first winnowing process, its
% information is stored in pulseInfo (this winnowing step just uses an amplitude threshold). If not, the 'comment' field
% of the pcndInfo structure will indicate why not.

pcndInfo.comment = cell(1,np);
zz = zeros(1,np);
pulseInfo.dog = zz; % the DoG order that best matches each pulse
pulseInfo.fcmx = zz;%the frequency of each pulse
pulseInfo.wc = zz; % location of the pulse peak
pulseInfo.w0 = zz; % start of window centered at wc
pulseInfo.w1 = zz; % end of window centered at wc

pulseInfo.x = cell(1,np); % the signals themselves
%pulseInfo.mxv = zz; %max voltage
%pulseInfo.aven = zz; %power

for i = 1:np
   
   % find the location of the pulse peak and set the pulse window

   peak = round(pcndInfo.wc(i));
   dog_at_max = cmh_dog(peak);
   sc_at_max = sc(dog_at_max+1,cmh_sc(peak));
   fc_at_max = fc(cmh_sc(peak));
   pcndInfo.dog(i) = dog_at_max;
   pcndInfo.fcmx(i) = fc_at_max;
   pcndInfo.scmx(i) = sc_at_max;
   
%    pulsewin = [];
   pulsewin = 2*sp.pulsewindow;
   
   %pcndInfo.w0(i) = round(peak-pulsewin*sc_at_max); %use this if you want
   %to scale the window around each pulse based on frequency
   pcndInfo.w0(i) = round(peak-pulsewin); 
   if pcndInfo.w0(i) < 0;
       pcndInfo.w0(i) = 1;
   end
   %pcndInfo.w1(i) = round(peak+pulsewin*sc_at_max); %use this if you want
   %to scale the window around each pulse based on frequency
   pcndInfo.w1(i) = round(peak+pulsewin); 
   if pcndInfo.w1(i) > length(xs);
       pcndInfo.w1(i) = length(xs);
   end
   
   %=======Don't include very small pulses (below the noise threshold defined by d*mean(xempty))========
   w0 = pcndInfo.w0(i);
   w1 = pcndInfo.w1(i);
   y = max(abs(xs(w0:w1)));

   if (y<sp.wnwMinAbsVoltage)
%       fprintf('%8.3f', pcndInfo.wc(i)./Fs);
%       fprintf('TOO LOW.\n');
       pcndInfo.comment{i} = 'tlav';    
       continue;
   else
       %fprintf('OK.\n');
   end
   
   indPulse(max(pcndInfo.w0(i),1):min(pcndInfo.w1(i),numel(xs)))=1;
   %pcndInfo.ok(i) = 1;
   nOk = nOk+1;
   
   pulseInfo.dog(nOk) = pcndInfo.dog(i);
   pulseInfo.fcmx(nOk) = pcndInfo.fcmx(i);
   pulseInfo.scmx(nOk) = pcndInfo.scmx(i);
   pulseInfo.wc(nOk) = pcndInfo.wc(i);
   pulseInfo.w0(nOk) = pcndInfo.w0(i);
   pulseInfo.w1(nOk) = pcndInfo.w1(i);   
  
   pulseInfo.x{nOk} = xs(w0:w1);
   %pulseInfo.aven(nOk) = mean(xs(w0:w1).^2);
   %pulseInfo.mxv(nOk) = max(abs(xs(w0:w1)));   
end

if (nOk)
  pulseInfo.dog = pulseInfo.dog(1:nOk);
  pulseInfo.fcmx = pulseInfo.fcmx(1:nOk);
  pulseInfo.scmx = pulseInfo.scmx(1:nOk);
  pulseInfo.wc = pulseInfo.wc(1:nOk);
  pulseInfo.w0 = pulseInfo.w0(1:nOk);
  pulseInfo.w1 = pulseInfo.w1(1:nOk);
  %pulseInfo.aven = pulseInfo.aven(1:nOk);
  pulseInfo.x = pulseInfo.x(1:nOk);
  %pulseInfo.mxv = pulseInfo.mxv(1:nOk);
end

if pulseInfo.w0==0;
    zz = zeros(1,10);
    pulseInfo2.w0=zz;
    fprintf('no pulses made it through first round of winnowing and into pulseInfo.\n');
    return
end
   
%%
%SECOND WINNOW
%Collecting pulses in pulseInfo2:
fprintf('WINNOWING PULSES FURTHER.\n');

%now that you have collected pulses in pulseInfo, winnow further:
indPulse = 0*xs;
np = length(pulseInfo.w0);

nOk = 0;

zz = zeros(1,np);
pulseInfo2.dog = zz; % the DoG order at max
pulseInfo2.fcmx = zz;
pulseInfo2.wc = zz; % location of peak correlation
pulseInfo2.w0 = zz; % start of window centered at wc
pulseInfo2.w1 = zz; % end of window centered at wc
pulseInfo2.x = cell(1,np); % the signals themselves
%pulseInfo2.mxv = zz;
%pulseInfo2.aven = zz;


for i = 1:np;
    
%======Don't include pulse > certain frequency==========

if pulseInfo.fcmx(i)>sp.frequency
%    fprintf('%8.2f', pulseInfo.w0(i)./Fs);
%    fprintf(' PULSE IS > k.\n');
    continue
end

%======Don't include pulses without another pulse (either before or after) within segParams.IPI samples==========:
    a=[];
    b=[];
    c=[];
    a = pulseInfo.w0(i);
    if i < np;
        b = pulseInfo.w0(i+1);
    elseif i == np;
        b = pulseInfo.w0(i);
    end
    
    if i>1;
        c = pulseInfo.w0(i-1);
    elseif i == 1;
        c = pulseInfo.w0(i);
    end
    
    if b-a>sp.IPI && a-c>sp.IPI; 
%        fprintf('%8.2f', pulseInfo.w0(i)./Fs);
%        fprintf(' NO PULSE WITHIN j samples.\n');
        continue;
    end
    
%=====If pulses are close together (parameter sp.close), keep the larger pulse===========
%     a0=[];
%     a1=[];
    b0=[];
%     b1=[];
    c0=[];
%     c1=[];
    a0 = pulseInfo.w0(i);
    a1 = pulseInfo.w1(i);
    y = max(abs(xs(a0:a1))); %pulse peak
    if i < np;
        b0 = pulseInfo.w0(i+1);
        b1 = pulseInfo.w1(i+1);
        y1 = max(abs(xs(b0:b1))); %next pulse peak
    elseif i == np;
        b0 = a0;
        b1 = a1;
        y1 = y;
    end
    
    if i>1;
        c0 = pulseInfo.w0(i-1);
        c1 = pulseInfo.w1(i-1);
        y0 = max(abs(xs(c0:c1))); %previous pulse peak
    elseif i == 1;
        c0 = a0;
        c1 = a1;
        y0 = y;
    end
    
    if b0-a0 < sp.close & y<y1; %if the pulse is within lms of the pulse after it and is smaller in amplitude 
%        fprintf('%8.2f', pulseInfo.w0(i)./Fs);
%        fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;
    elseif b0-a0 < sp.close & y==y1; %if the pulse is within lms of the pulse after it and is the same in amplitude 
%        fprintf('%8.2f', pulseInfo.w0(i)./Fs);
%        fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;
    elseif a0-c0 < sp.close & y<y0; %if the pulse is within lms of the pulse before it and is smaller in amplitude
%        fprintf('%8.2f', pulseInfo.w0(i)./Fs);
%        fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;  
    end
          
   indPulse(max(pulseInfo.w0(i),1):min(pulseInfo.w1(i),numel(xs)))=1;
   %pulseInfo2.ok(i) = 1;
   nOk = nOk+1;
   
   pulseInfo2.dog(nOk) = pulseInfo.dog(i);
   pulseInfo2.fcmx(nOk) = pulseInfo.fcmx(i);
   pulseInfo2.scmx(nOk) = pulseInfo.scmx(i);
   pulseInfo2.wc(nOk) = pulseInfo.wc(i);
   pulseInfo2.w0(nOk) = pulseInfo.w0(i);
   pulseInfo2.w1(nOk) = pulseInfo.w1(i);   
   pulseInfo2.x{nOk} = pulseInfo.x{i};
   %pulseInfo2.aven(nOk) = pulseInfo.aven(i);
   %pulseInfo2.mxv(nOk) = pulseInfo.mxv(i);
end

if (nOk)
  pulseInfo2.dog = pulseInfo2.dog(1:nOk);
  pulseInfo2.fcmx = pulseInfo2.fcmx(1:nOk);
  pulseInfo2.scmx = pulseInfo2.scmx(1:nOk);
  pulseInfo2.wc = pulseInfo2.wc(1:nOk);
  pulseInfo2.w0 = pulseInfo2.w0(1:nOk);
  pulseInfo2.w1 = pulseInfo2.w1(1:nOk);
  %pulseInfo2.aven = pulseInfo2.aven(1:nOk);
  pulseInfo2.x = pulseInfo2.x(1:nOk);
  %pulseInfo2.mxv = pulseInfo2.mxv(1:nOk);
end

if pulseInfo2.w0==0;
    fprintf('no pulses made it through second round of winnowing and into pulseInfo2.\n');
    return
end

fprintf('%d/%d (%2.1f %%) pulses passed second stage of winnowing.\n',nOk,np,nOk*100/np)
fprintf('DONE.\n');
