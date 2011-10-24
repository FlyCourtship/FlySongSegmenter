function [indPulse pulse] = findPulses(signal,spr,H,highCut,nPointSmooth,numPBefore,numPAfter)


% [indPulse pulse] = findPulses(signal,spr,th,H,highCut,nPointSmooth,numPBefore,numPAfter)
% This function finds pulses in fly songs. It returns indPulse and pulse.
% indPulse is the index of the start of the detected pulse.
% pulse contain each pulse. It is an NxM matrix with N equal to the number
% of pulses and M the number of points in each pulse
% (M = numPBefore + numPAfter + 1);
% The paramters below work ok for the "fishbones" data from Mala, Semptember 2011.
% signal = raw song data
% spr = 10000;  recording sampling rate
%%%% th = 1; th is NOW AUTOMATIC. NOT AN INPUT ANYMORE. th is a factor used to multiply
% the std of the filtered signal and create a threshold. 
% H = 6; signal to the power H (to increase differences between peaks)
% highCut = 15;  highpass cutoff of a filter (see code below)
% nPointSmooth = 81; number of points used in smooth.m
% numPBefore = 20; number of points used before the detected pulse 
% numPAfter = 100; number of points used after the detected pulse

toPlot = 'y'; % set to anything else to switch plotting off 

signalToH = signal.^H;


signalToH_f = smooth(signalToH,nPointSmooth);
signalRoot = signalToH_f.^(1/H);

% highpass filter to remove very slow changes and DC
[bh ah] = butter(4,highCut/(spr/2),'high');
signal_f = filtfilt(bh,ah,signalRoot);


%signalToLookAt = signalRoot;
signalToLookAt = signal_f;

stdS = std(signalToLookAt);
% Automatic th (might need better adjustment)
%Logic: if std is small the SNR is small (small or no pulse) and thus the
%threshold need to be high (e.g. 3*std) to avoid false positives
if stdS < .4
    th = 2.3;
else
    th = .5;
end

indLarger = find(signalToLookAt > stdS*th);
newIndLarger = zeros(1,length(indLarger)+1);
newIndLarger(2:length(indLarger)+1) = indLarger;
indLarger = newIndLarger;

indPulse = indLarger(find(diff(indLarger)~=1)+1);
tooSmall = find(indPulse<=numPBefore);
indPulse(tooSmall) = [];
% tooLarge = find(indPulse>=length(signal) + numPAfter);
% indPulse(tooLarge) = [];


 tp = 0:spr^-1:(numPBefore+numPAfter)/spr;
 for p = 1:length(indPulse)
     if (indPulse(p)+numPAfter) > length(signal)
         signal(end+1:indPulse(p)+numPAfter) = 0;
     end
     
     pulse(p,:) = signal(indPulse(p)-numPBefore:indPulse(p)+numPAfter);
%     fftPulse(p,:) = fft(pulse(p,:),2^(nextpow2(length(pulse(p,:)))));
 end


switch toPlot
    case 'y'
figure('position',[506 31 512 655])
t = 0:spr^-1:(length(signal)-1)/spr;
subplot(2,1,1)
plot(t,signal)
hold on
plot(t(indPulse),1,'r*')
title('Original signal with detected start of pulses')
xlabel('Time (ms)')

tt = 0:spr^-1:(length(signalToLookAt)-1)/spr;
subplot(2,1,2)
plot(tt,signalToLookAt)
hold on
plot([tt(1) tt(end)],[stdS*th stdS*th],'r-')
title('Filtered signal with threshold')
xlabel('Time (s)')


figure('name','each Pulse',...
        'position',[2    29   512   384]);
hold on
for i = 1:size(pulse,1)
    pp = plot(1000*tp,pulse(i,:),'k-');
    set(pp,'tag',num2str(i));
end
xlabel('Time (s)')
title('Each detected pulse (not aligned)')

%keyboard
end


