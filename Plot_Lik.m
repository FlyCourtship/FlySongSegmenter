function Plot_Lik(ssf,pulseInfo,winnowed_sine,labels,Lik_pulse,LOD_pulse)
%Plot_Lik(ssf,pulseInfo,winnowed_sine,labels,Lik_pulse,LOD_pulse)
%USAGE
%
%Plot_Lik(ssf,pulseInfo2,winnowed_sine,[],Lik_pulse.Lik)
%
%Plot with pulses labeled (default no labels, much faster plotting)
%Plot_Lik(ssf,pulseInfo2,winnowed_sine,'yes',Lik_pulse.Lik)
%
%
%

addpath ./lscatter

Lik = Lik_pulse;

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
    %legend(ax2,'Lik','LR');
else
    %legend(ax2,'Lik');
end

linkaxes([ax1 ax2],'x');
zoom xon;


% plot sine data
if winnowed_sine.num_events>0
    for n = 1:size(winnowed_sine.start,1)
        x_start = round(winnowed_sine.start(n)*ssf.fs);
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
    %
    % %plot pulse data
    n = length(pulseInfo.x);
    wc = nan(1,n); %NaNs the length of n (number of pulses in pulseInfo2)
    mxv = nan(1,n);
    for i = 1:n
        wc(i) = pulseInfo.wc(i)/ssf.fs;
        mxv(i) = pulseInfo.mxv(i);
    end
    
    if strcmp(labels,'yes') == 1 %user specifies labels
        hold on;
        points = 1:n;
        subplot(ax1);
        lscatter(wc,mxv+mxv./10,points);
        subplot(ax2);
        lscatter(wc,mxv,points);
    end
end


%title('Sine & Pulses','FontSize',14);
%legend('Signal','Sine','Pulses','Pulse Peaks');


hold off



