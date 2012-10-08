function PlotSegmentation(data,Sines,Pulses)
%PlotSegmentation(data,Sines,Pulses)
%A utility to examine the likelihood scores for pulses
%USAGE
%Plot_Lik(data,pulseInfo2,winnowed_sine,Lik_pulse.LLR_best)
%
%

ssf=data;
figure; clf;
%plot the signal
ax1 = subplot(2,1,1);
set(ax1,'XLim',[0 length(ssf.d)],'YLim', [-max(abs(ssf.d+.02)) max(abs(ssf.d+.02))])
plot(ax1,(1:length(ssf.d))./ssf.fs,ssf.d,'Color',[.742 .742 .742]);
hold on; 


ax2 = subplot(2,1,2);

hold on
scatter(ax2,Pulses.AmpCull.wc/ssf.fs,Pulses.Lik_pulse.LLR_best,35,'m','filled');
scatter(ax2,Pulses.IPICull.wc/ssf.fs,Pulses.Lik_pulse2.LLR_best,35,'k','filled');
xlim(ax2,[0 length(ssf.d)/ssf.fs]);
title(ax2,'LLR','FontSize',10);
if nargin == 8
    scatter(ax2,Pulses.AmpCull.wc/ssf.fs,LOD_pulse,35,'b','filled');
end

linkaxes([ax1 ax2],'x');
zoom xon;


% plot sine data
num_events=length(Sines.LengthCull.start);
if num_events>0
    for n = 1:size(Sines.LengthCull.start,1)
        x_start = round(Sines.LengthCull.start(n));
        x_stop = round(x_start + size(Sines.LengthCull.clips{n},1));
        time = (x_start:x_stop-1);
        y = Sines.LengthCull.clips{n};
        plot(ax1,time./ssf.fs,y,'b')
    end
end



if numel(Pulses.AmpCull) > 0
    for i = 1:length(Pulses.AmpCull.x);
        a = Pulses.AmpCull.w0(i);
        b = Pulses.AmpCull.w1(i);
        t = (a:b);
        y = ssf.d(a:b);
        plot(ax1,t./ssf.fs,y,'r'); %hold on;
    end

end

grid on
hold off
