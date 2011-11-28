function plot_ipitime(pulseInfo,fs)
%blue is distribution of ipis, red is scaled by amount of time performing
%ipis of that length

ipi = fit_ipi_model(pulseInfo,fs);

edges = 0:.001:1;
n = histc(ipi.d,edges);
scale = std(n);

figure(1);
hold on
plot(n);
plot(scale * (n .*edges),'r')
hold off