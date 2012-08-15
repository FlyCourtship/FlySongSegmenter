%function freq_resp_plot(varargin)
%
%use freq_resp_plot(filename) when calling from the matlab command line

function freq_resp_plot(varargin)

if(nargin==7)
  freq=varargin{1};
  amp=varargin{2};
  phi=varargin{3};
  ambient=varargin{4};
  distortion=varargin{5};
  raw_ambient=varargin{6};
  Fs=varargin{7};
elseif(nargin==1)
  load([varargin{1} '_fr.mat']);
else
  error('bad input arguments');
end

figure;

subplot(2,2,1);  hold on;
plot(freq,20*log10(amp),'k.-');
set(gca,'xscale','log');
ylabel('magnitude (dB)');
axis tight;

subplot(2,2,2);  hold on;
plot(freq,100*distortion,'k.-');
set(gca,'xscale','log','yscale','log');
ylabel('distortion (%)');
axis tight;

subplot(2,2,3);  hold on;
uphi=unwrap(phi);
plot(freq,uphi*180/pi,'k.-');
set(gca,'xscale','log');
xlabel('freq (Hz)');
ylabel('phase (deg)');
axis tight;

subplot(2,2,4);  hold on;
[pxx f]=pwelch(raw_ambient,[],[],[],Fs);
pxx=sqrt(pxx)./interp1(freq,amp,f);
idx=find((f>=freq(1))&(f<=freq(end)));
plot(f(idx),pxx(idx),'r-');
plot(freq,ambient,'k.-');
ylabel('noise (V/rHz)');
xlabel('freq (Hz)');
set(gca,'xscale','log','yscale','log');
axis tight;

bw=[200 2000];  gain=1;
[b,a]=butter(4,bw./(Fs/2));
tmp=sqrt(mean(filtfilt(b,a,raw_ambient).^2));
tmp=tmp/gain;