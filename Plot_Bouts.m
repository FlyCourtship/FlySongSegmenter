function Plot_Bouts(data,bouts)

d = data.d;
boutstart=bouts.Start;
boutstop = bouts.Stop;

figure; clf;
%plot the signal
plot(d,'Color',[.742 .742 .742]);
hold on; 


% plot bouts in color
for n = 1:length(boutstart)
    vec =boutstart(n):boutstop(n);
    plot(vec,d(vec),'b')
end




%title('Sine & Pulses','FontSize',14);
%legend('Signal','Sine','Pulses','Pulse Peaks');

grid on
hold off



