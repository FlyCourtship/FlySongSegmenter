%function [Wavelet AmpCull IPICull] = CullPulses(Wavelet,cmh_dog,cmh_sc,sc,xs,xn,a, b, c, d, e, f, g, h, i, Fs)
function [Wavelet AmpCull IPICull] = CullPulses(Wavelet,cmh_dog,cmh_sc,sc,xs,xn, ...
    fc, pWid, wnwMinAbsVoltage, maxIPI, frequency, close)

%========PARAMETERS=================
%segParams.fc = a; % frequencies examined. These will be converted to CWT scales later on.
%segParams.DoGwvlt = b; % Derivative of Gaussian wavelets examined
%segParams.pWid = c; %pWid: Approx Pulse Width in points (odd, rounded)
%segParams.pulsewindow = round(c); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)
%segParams.pulsewindow = round(pWid); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)
pulsewindow = round(pWid); %factor for computing window around pulse peak (this determines how much of the signal before and after the peak is included in the pulse)
%segParams.lowIPI = d; %lowIPI: estimate of a very low IPI (even, rounded)
%segParams.thresh = e; %thresh: Proportion of smoothed threshold over which pulses are counted.
%segParams.wnwMinAbsVoltage = f*mean(abs(xn));
wnwMinAbsVoltage = wnwMinAbsVoltage*mean(abs(xn));
%for 2nd winnow
%segParams.IPI = g; %in samples, if no other pulse within this many samples, do not count as a pulse (the idea is that a single pulse (not within IPI range of another pulse) is likely not a true pulse)
%segParams.frequency = h; %if AmpCull.fcmx is greater than this frequency, then don't include pulse
%segParams.close = i; %if pulse peaks are this close together, only keep the larger pulse
%sp = segParams;

%fc = sp.fc;
       
%%
       
       
if Wavelet.wc==0;
    zz = zeros(1,10);
    AmpCull.w0 = zz;
    IPICull.w0=zz;
    return
end

%%
%FIRST WINNOW
%Collecting pulses in AmpCull (removing those below the noise threshold):
%fprintf('Winnowing pulses.\n');

indPulse = 0*xs;
np = numel(Wavelet.wc); %the number of pulses total

nOk = 0;

% Wavelet contains all pulse candidates. If a pulse makes it past the first winnowing process, its
% information is stored in AmpCull (this winnowing step just uses an amplitude threshold). If not, the 'comment' field
% of the Wavelet structure will indicate why not.

Wavelet.comment = cell(1,np);
zz = zeros(1,np);
AmpCull.dog = zz; % the DoG order that best matches each pulse
AmpCull.fcmx = zz;%the frequency of each pulse
AmpCull.wc = zz; % location of the pulse peak
AmpCull.w0 = zz; % start of window centered at wc
AmpCull.w1 = zz; % end of window centered at wc

AmpCull.x = cell(1,np); % the signals themselves
%AmpCull.mxv = zz; %max voltage
%AmpCull.aven = zz; %power

for i = 1:np
   
   % find the location of the pulse peak and set the pulse window

   peak = round(Wavelet.wc(i));
   dog_at_max = cmh_dog(peak);
   sc_at_max = sc(dog_at_max,cmh_sc(peak));
   fc_at_max = fc(cmh_sc(peak));
   Wavelet.dog(i) = dog_at_max;
   Wavelet.fcmx(i) = fc_at_max;
   Wavelet.scmx(i) = sc_at_max;
   
% pulsewin = [];
   %pulsewin = 2*sp.pulsewindow;
   pulsewin = 2*pulsewindow;
   
   %Wavelet.w0(i) = round(peak-pulsewin*sc_at_max); %use this if you want
   %to scale the window around each pulse based on frequency
   Wavelet.w0(i) = round(peak-pulsewin);
   if Wavelet.w0(i) < 0;
       Wavelet.w0(i) = 1;
   end
   %Wavelet.w1(i) = round(peak+pulsewin*sc_at_max); %use this if you want
   %to scale the window around each pulse based on frequency
   Wavelet.w1(i) = round(peak+pulsewin);
   if Wavelet.w1(i) > length(xs);
       Wavelet.w1(i) = length(xs);
   end
   
   %=======Don't include very small pulses (below the noise threshold defined by d*mean(xn))========
   w0 = Wavelet.w0(i);
   w1 = Wavelet.w1(i);
   y = max(abs(xs(w0:w1)));

   %if (y<sp.wnwMinAbsVoltage)
   if (y<wnwMinAbsVoltage)
% fprintf('%8.3f', Wavelet.wc(i)./Fs);
% fprintf('TOO LOW.\n');
       Wavelet.comment{i} = 'tlav';
       continue;
   else
       %fprintf('OK.\n');
   end
    
   indPulse(max(Wavelet.w0(i),1):min(Wavelet.w1(i),numel(xs)))=1;
   %Wavelet.ok(i) = 1;
   nOk = nOk+1;
   
   AmpCull.dog(nOk) = Wavelet.dog(i);
   AmpCull.fcmx(nOk) = Wavelet.fcmx(i);
   AmpCull.scmx(nOk) = Wavelet.scmx(i);
   AmpCull.wc(nOk) = Wavelet.wc(i);
   AmpCull.w0(nOk) = Wavelet.w0(i);
   AmpCull.w1(nOk) = Wavelet.w1(i);
  
   AmpCull.x{nOk} = xs(w0:w1);
   %AmpCull.aven(nOk) = mean(xs(w0:w1).^2);
   %AmpCull.mxv(nOk) = max(abs(xs(w0:w1)));
end

if (nOk)
  AmpCull.dog = AmpCull.dog(1:nOk);
  AmpCull.fcmx = AmpCull.fcmx(1:nOk);
  AmpCull.scmx = AmpCull.scmx(1:nOk);
  AmpCull.wc = AmpCull.wc(1:nOk);
  AmpCull.w0 = AmpCull.w0(1:nOk);
  AmpCull.w1 = AmpCull.w1(1:nOk);
  %AmpCull.aven = AmpCull.aven(1:nOk);
  AmpCull.x = AmpCull.x(1:nOk);
  %AmpCull.mxv = AmpCull.mxv(1:nOk);
end

if AmpCull.w0==0;
    zz = zeros(1,10);
    IPICull.w0=zz;
    fprintf('no pulses made it through first round of winnowing and into AmpCull.\n');
    return
end
   
%%
%SECOND WINNOW
%Collecting pulses in IPICull:

%now that you have collected pulses in AmpCull, winnow further:
indPulse = 0*xs;
np = length(AmpCull.w0);

nOk = 0;

zz = zeros(1,np);
IPICull.dog = zz; % the DoG order at max
IPICull.fcmx = zz;
IPICull.wc = zz; % location of peak correlation
IPICull.w0 = zz; % start of window centered at wc
IPICull.w1 = zz; % end of window centered at wc
IPICull.x = cell(1,np); % the signals themselves
%IPICull.mxv = zz;
%IPICull.aven = zz;


for i = 1:np;
    
%======Don't include pulse > certain frequency==========

%if AmpCull.fcmx(i)>sp.frequency
if AmpCull.fcmx(i)>frequency
% fprintf('%8.2f', AmpCull.w0(i)./Fs);
% fprintf(' PULSE IS > k.\n');
    continue
end

%======Don't include pulses without another pulse (either before or after) within segParams.IPI samples==========:
    a=[];
    b=[];
    c=[];
    a = AmpCull.w0(i);
    if i < np;
        b = AmpCull.w0(i+1);
    elseif i == np;
        b = AmpCull.w0(i);
    end
    
    if i>1;
        c = AmpCull.w0(i-1);
    elseif i == 1;
        c = AmpCull.w0(i);
    end
    
    %if b-a>sp.IPI && a-c>sp.IPI;
    if b-a>maxIPI && a-c>maxIPI;
% fprintf('%8.2f', AmpCull.w0(i)./Fs);
% fprintf(' NO PULSE WITHIN j samples.\n');
        continue;
    end
    
%=====If pulses are close together (parameter sp.close), keep the larger pulse===========
% a0=[];
% a1=[];
    b0=[];
% b1=[];
    c0=[];
% c1=[];
    a0 = AmpCull.w0(i);
    a1 = AmpCull.w1(i);
    y = max(abs(xs(a0:a1))); %pulse peak
    if i < np;
        b0 = AmpCull.w0(i+1);
        b1 = AmpCull.w1(i+1);
        y1 = max(abs(xs(b0:b1))); %next pulse peak
    elseif i == np;
        b0 = a0;
        b1 = a1;
        y1 = y;
    end
    
    if i>1;
        c0 = AmpCull.w0(i-1);
        c1 = AmpCull.w1(i-1);
        y0 = max(abs(xs(c0:c1))); %previous pulse peak
    elseif i == 1;
        c0 = a0;
        c1 = a1;
        y0 = y;
    end
    
    %if b0-a0 < sp.close & y<y1; %if the pulse is within lms of the pulse after it and is smaller in amplitude
    if b0-a0 < close & y<y1; %if the pulse is within lms of the pulse after it and is smaller in amplitude
% fprintf('%8.2f', AmpCull.w0(i)./Fs);
% fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;
%    elseif b0-a0 < sp.close & y==y1; %if the pulse is within lms of the pulse after it and is the same in amplitude
    %elseif b0-a0 < sp.close & i~=np & y==y1;
    elseif b0-a0 < close & i~=np & y==y1;
% fprintf('%8.2f', AmpCull.w0(i)./Fs);
% fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;
    %elseif a0-c0 < sp.close & y<y0; %if the pulse is within lms of the pulse before it and is smaller in amplitude
    elseif a0-c0 < close & y<y0; %if the pulse is within lms of the pulse before it and is smaller in amplitude
% fprintf('%8.2f', AmpCull.w0(i)./Fs);
% fprintf(' NOT A TRUE PULSE - too close.\n');
        continue;
    end
          
   indPulse(max(AmpCull.w0(i),1):min(AmpCull.w1(i),numel(xs)))=1;
   %IPICull.ok(i) = 1;
   nOk = nOk+1;
   
   IPICull.dog(nOk) = AmpCull.dog(i);
   IPICull.fcmx(nOk) = AmpCull.fcmx(i);
   IPICull.scmx(nOk) = AmpCull.scmx(i);
   IPICull.wc(nOk) = AmpCull.wc(i);
   IPICull.w0(nOk) = AmpCull.w0(i);
   IPICull.w1(nOk) = AmpCull.w1(i);
   IPICull.x{nOk} = AmpCull.x{i};
   %IPICull.aven(nOk) = AmpCull.aven(i);
   %IPICull.mxv(nOk) = AmpCull.mxv(i);
end

if (nOk)
  IPICull.dog = IPICull.dog(1:nOk);
  IPICull.fcmx = IPICull.fcmx(1:nOk);
  IPICull.scmx = IPICull.scmx(1:nOk);
  IPICull.wc = IPICull.wc(1:nOk);
  IPICull.w0 = IPICull.w0(1:nOk);
  IPICull.w1 = IPICull.w1(1:nOk);
  %IPICull.aven = IPICull.aven(1:nOk);
  IPICull.x = IPICull.x(1:nOk);
  %IPICull.mxv = IPICull.mxv(1:nOk);
end

if isempty(IPICull.w0) | (IPICull.w0==0)
    fprintf('no pulses made it through second round of winnowing and into IPICull.\n');
    return
end

%collect together pcnd.x
Wavelet.x = cell(length(Wavelet.w0),1);
for i =1:length(Wavelet.w0)
    Wavelet.x{i} = xs(Wavelet.w0(i):Wavelet.w1(i));
end

%fprintf('%d/%d (%2.1f %%) pulses passed second stage of winnowing.\n',nOk,np,nOk*100/np)
%fprintf('DONE.\n');
