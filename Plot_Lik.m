function Plot_Lik(data,pulseInfo,winnowed_sine,Lik_pulse)
%Plot_Lik(data,pulseInfo,winnowed_sine,Lik_pulse)
%A utility to examine the likelihood scores for pulses
%USAGE
%Plot_Lik(data,pulseInfo2,winnowed_sine,Lik_pulse.LLR_best)
%
%

Lik = Lik_pulse;
ssf=data;
figure; clf;
%plot the signal
ax1 = subplot(2,1,1);
set(ax1,'XLim',[0 length(ssf.d)],'YLim', [-max(abs(ssf.d+.02)) max(abs(ssf.d+.02))])
plot(ax1,(1:length(ssf.d))./ssf.fs,ssf.d,'Color',[.742 .742 .742]);
hold on; 


ax2 = subplot(2,1,2);

scatter(ax2,pulseInfo.wc/ssf.fs,Lik,35,'r','filled');
xlim(ax2,[0 length(ssf.d)/ssf.fs]);
title(ax2,'LLR','FontSize',10);
hold on
if nargin == 6
    scatter(ax2,pulseInfo.wc/ssf.fs,LOD_pulse,35,'b','filled');
end

linkaxes([ax1 ax2],'x');
zoom xon;


% plot sine data
num_events=length(winnowed_sine.start);
if num_events>0
    for n = 1:size(winnowed_sine.start,1)
        x_start = round(winnowed_sine.start(n));
        x_stop = round(x_start + size(winnowed_sine.clips{n},1));
        time = (x_start:x_stop-1);
        y = winnowed_sine.clips{n};
        plot(ax1,time./ssf.fs,y,'b')
    end
end



if numel(pulseInfo) > 0
    for i = 1:length(pulseInfo.x);
        a = pulseInfo.w0(i);
        b = pulseInfo.w1(i);
        t = (a:b);
        y = ssf.d(a:b);
        plot(ax1,t./ssf.fs,y,'r'); %hold on;
    end

end

grid on
hold off



