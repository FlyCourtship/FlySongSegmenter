t = 1:size(data.d); %10 minutes
% t = 1:8471552; %10 minutes
f = 1/55e4;%freq = 1/period
% fs = 1e4;
A = 0.002; %amplitude ~2msec
% A = 1;
x = A *sin(2*pi*f*t);
 
% plot(t,x)

culled_ipi = ipiStatsLomb.culled_ipi;
cx = x(culled_ipi.t);
ct = culled_ipi.t;
% plot(ct,cx,'.-')
%  
% lomb(cx,ct./fs,1);
 
%Now try adding variance to cx
SNR = .4;
% rmsrnd = sqrt(mean(randn(size(x,2),1).^2));
% rmsx = sqrt(mean(x.^2));

stdx = std(culled_ipi.d./1e4);
 
% noise = (1/.7088)*(rmsx/SNR) .* randn(size(cx,2),1);
noised = (1/.7088)*(stdx/SNR) .* randn(size(cx,2),1);

% cy = cx+noise';
cyd = cx+noised';

% plot(ct,cy,'.-')
% lomb(cy,ct./fs,1);

plot(ct,cyd,'.-')
lomb(cyd,ct./fs,1);

%%%%%%%%%%%%%%%%%%%
%check rmsq vs rmsrnd
% t = 1:size(data.d); %10 minutes
% f = 1/55e4;%freq = 1/period
% A = 1;
% x = A *sin(2*pi*f*t);
% rmsx = sqrt(mean(x.^2))
% rmsrnd = sqrt(mean(randn(size(x,2),1).^2))
