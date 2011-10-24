
function sineppsplot(ssf,sine,pps)

ax1=subplot(2,1,1);
title('sine song');
axis tight

plot((1:size(ssf.d,1))./ssf.fs,ssf.d,'k')
hold on
for n = 1:size(sine.start,1)
    x_start = round(sine.start(n)*ssf.fs);
    x_stop = round(x_start + size(sine.clips{n},1));
    t = (x_start:x_stop-1);
    y = sine.clips{n};
    plot(t./ssf.fs,y,'b')
end
hold off
zoom xon

ax2=subplot(2,1,2);
title('all song');
plot((1:size(ssf.d,1))./ssf.fs,ssf.d,'k')
hold on

for n = 1:numel(pps.start)
    x_start = round(pps.start(n)*ssf.fs);
    x_stop = x_start + numel(pps.clips{n});
    t = (x_start:x_stop-1);
    plot(t./ssf.fs,pps.clips{n},'r')
end
hold off
xlabel('time (s)');
zoom xon

linkaxes([ax1 ax2],'x');
