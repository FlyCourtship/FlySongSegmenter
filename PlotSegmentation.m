function PlotSegmentation(data,sines,pulses,region)
% PlotSegmentation(data,Sines,Pulses)
% A utility to examine the likelihood scores for pulses
% region is optional range of data to plot
% USAGE
% Plot_Lik(data,Sines,Pulses,[1e6 1.2e6])
%
%

if nargin == 4 %trim relevant field to region
    Data.d = data.d(region(1):region(2));
    Data.t = (region(1):region(2));
    Sines.LengthCull.start = sines.LengthCull.start(sines.LengthCull.start > region(1) & sines.LengthCull.stop < region(2));
    Sines.LengthCull.stop= sines.LengthCull.stop(sines.LengthCull.start > region(1) & sines.LengthCull.stop < region(2));
    Pulses.AmpCull.w0 = pulses.AmpCull.w0(pulses.AmpCull.w0 > region(1) & pulses.AmpCull.w1 < region(2));
    Pulses.AmpCull.w1 = pulses.AmpCull.w1(pulses.AmpCull.w0 > region(1) & pulses.AmpCull.w1 < region(2));
    Pulses.AmpCull.wc = pulses.AmpCull.wc(pulses.AmpCull.w0 > region(1) & pulses.AmpCull.w1 < region(2));
    Pulses.IPICull.wc = pulses.IPICull.wc(pulses.IPICull.w0 > region(1) & pulses.IPICull.w1 < region(2));
    Pulses.ModelCull2.w0 = pulses.ModelCull2.w0(pulses.ModelCull2.w0 > region(1) & pulses.ModelCull2.w1 < region(2));
    Pulses.ModelCull2.w1 = pulses.ModelCull2.w1(pulses.ModelCull2.w0 > region(1) & pulses.ModelCull2.w1 < region(2));
    Pulses.ModelCull2.wc = pulses.ModelCull2.wc(pulses.ModelCull2.w0 > region(1) & pulses.ModelCull2.w1 < region(2));
    Pulses.Lik_pulse.LLR_best = pulses.Lik_pulse.LLR_best(pulses.AmpCull.w0 > region(1) & pulses.AmpCull.w1 < region(2));
    Pulses.Lik_pulse2.LLR_best = pulses.Lik_pulse2.LLR_best(pulses.IPICull.w0 > region(1) & pulses.IPICull.w1 < region(2));
else
    Data.d = data.d;
    Data.fs = data.fs;
    Sines = sines;
    Pulses = pulses;
    region = [0 0];
end

DataFromStart = vertcat(zeros(region(1)-1,1),Data.d);

Sines.LengthCull.clips = GetClips(Sines.LengthCull.start,Sines.LengthCull.stop,DataFromStart);
Pulses.AmpCull.x = GetClips(Pulses.AmpCull.w0,Pulses.AmpCull.w1,DataFromStart);
Pulses.ModelCull2.x = GetClips(Pulses.ModelCull2.w0,Pulses.ModelCull2.w1,DataFromStart);
sineMFFT = findSineMaxFFT(Sines.LengthCull,data.fs);
pulseMFFT = findPulseMaxFFT(Pulses.ModelCull2,data.fs);

figure; clf;
%plot the signal
ax1 = subplot(3,1,1);
ax2 = subplot(3,1,2);
ax3 = subplot(3,1,3);

set(ax1,'XLim',[0 length(Data.d)],'YLim', [-max(abs(Data.d+.02)) max(abs(Data.d+.02))])
plot(ax1,Data.t./data.fs,Data.d,'Color',[.742 .742 .742]);

hold(ax1 ,'on')
%plot pulse data
if numel(Pulses.AmpCull.x) > 0
    for i = 1:numel(Pulses.AmpCull.x);
        a = Pulses.AmpCull.w0(i);
        b = Pulses.AmpCull.w1(i);
        t = (a:b);
        y = DataFromStart(a:b);
        plot(ax1,t./data.fs,y,'r'); %hold on;
    end
end

% plot sine data

if numel(Sines.LengthCull.start)>0
    for n = 1:numel(Sines.LengthCull.start)
        x_start = round(Sines.LengthCull.start(n));
        x_stop = round(x_start + size(Sines.LengthCull.clips{n},1));
        time = (x_start:x_stop-1);
        y = Sines.LengthCull.clips{n};
        plot(ax1,time./data.fs,y,'b')
    end
end


hold(ax2 ,'on')
scatter(ax2,Pulses.AmpCull.wc/data.fs,Pulses.Lik_pulse.LLR_best,35,'m','filled');
scatter(ax2,Pulses.IPICull.wc/data.fs,Pulses.Lik_pulse2.LLR_best,35,'k','filled');
xlim(ax2,[region(1)/data.fs region(2)/data.fs]);
ylabel(ax2,'LLR','FontSize',10);
set(ax2,'YGrid','on')

% get sine and pulse MFFT 

hold(ax3 ,'on')
ylabel(ax3, 'Carrier Freq (Hz)','FontSize',10);
scatter(ax3,(sineMFFT.timeAll+5e2)./data.fs,sineMFFT.freqAll,35,'b','filled');
scatter(ax3,pulseMFFT.timeAll./data.fs,pulseMFFT.freqAll,35,'r','filled');
set(ax3,'YGrid','on')

linkaxes([ax1 ax2 ax3],'x');
zoom xon;
hold off