function crosstalk_fig(normal_file, crosstalk_file)
figure;

load([normal_file '_fr']);
tmp=amp;
load([crosstalk_file '_fr']);

hold on;
plot(freq,20*log10(amp./tmp),'k.-');
set(gca,'xscale','log');
ylabel('crosstalk (dB)');
xlabel('frequency (Hz)');
%set(gca,'xtick',[10 100 1000 10000],'xticklabel',[' 10 '; ' 100'; '1000'; '10k ']);
axis tight;
