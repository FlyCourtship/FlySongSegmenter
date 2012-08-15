%function [freq,amp,phi,ambient,distortion,raw,raw_ambient,Fs]=...
%    freq_resp_take(filename,freq,chan_out,chan_in,stim_amp,atten,nreps)
%
% amp is RMS amplitude
% atten is how much attenuation you have applied with the resistive divider
%   in dB
%
% freq_resp_take([],logspace(1,4,13),[0-1],[0-15],10,80,10);

function [freq,amp,phi,ambient,distortion,raw,raw_ambient,Fs]=...
    freq_resp_take(filename,freq,chan_out,chan_in,stim_amp,atten,nreps)

global Fs;

if(~isempty(filename))
  if(exist([filename '_fr.mat'])>0)
    error([filename ' already exists']);
  end
end

if((chan_out<0)|(chan_out>3))
  disp('ERROR: chan_out must be between 0 and 3');
  return;
end

if((chan_in<0)|(chan_in>31))
  disp('ERROR: chan_in must be between 0 and 31');
  return;
end

Fs=100e3;  range=10;
daq=daqhwinfo('nidaq','InstalledBoardIds');
daq=char(daq(1));

ai = analoginput('nidaq',daq);
ai.InputType = 'NonReferencedSingleEnded';
ai.TriggerType = 'Immediate';
ai.ExternalTriggerDriveLine = 'PFI2';
%set(ai,'InputType','SingleEnded');
ai0=addchannel(ai,chan_in);
ai0.InputRange = [-range range];

ao = analogoutput('nidaq',daq);
ao.TriggerType = 'HwDigital';
ao.HwDigitalTriggerSource = 'PFI10';
ao0=addchannel(ao,chan_out);

set([ai ao],'SampleRate',Fs);

if(sum(freq>(Fs/2))>0)
  disp('ERROR: some freqs are greater than the nyquist frequency');
  return;
end

len=0.2;
pre=len/2;
post=len;
rise_fall=0.01;
stim_offset=0;

pre_idx=1:floor(pre*Fs);
len_idx=ceil((pre+2*rise_fall)*Fs):floor((pre+len-2*rise_fall)*Fs);

tmp=round((pre+len+post)*Fs);
set(ai,'SamplesPerTrigger',tmp);
putdata(ao,zeros(tmp,1));
start(ao);
start(ai);
wait([ai ao],2*(pre+len+post));
in = getdata(ai)';
stop([ai ao]);

raw_ambient=in;

for(i=1:length(freq))
  in=zeros(1,tmp);
  for(j=1:nreps)
    out=stim_amp.*cosine_envelope(sin(2*pi*freq(i)*(1:round(len*Fs))/Fs),rise_fall,rise_fall,Fs);
    out=[zeros(1,round(pre*Fs)) out zeros(1,round(post*Fs))];
    out=stim_offset+out;
    set(ai,'SamplesPerTrigger',length(out));
    putdata(ao,out');
    start(ao);
    start(ai);
    wait([ai ao],2*(pre+len+post));
    in = in+getdata(ai)';
    stop([ai ao]);

    figure(3);  clf;
    subplot(2,2,1);  plot(out,'k-');   axis tight;  title('out1');
    subplot(2,2,3);  plot(in,'k-');  axis tight;  title('in1');
    hold on;  v=axis;
    plot([len_idx(1) len_idx(1)],[v(3) v(4)],'r-');
    plot([len_idx(end) len_idx(end)],[v(3) v(4)],'r-');
    drawnow;
  end

  in=in./nreps;
  in=in-mean(in(pre_idx));
  raw(i,:)=in;
  [amp(i) phi(i)]=fit_sin(in(len_idx),freq(i),Fs);
  [ambient(i) foo]=fit_sin(raw_ambient(len_idx),freq(i),Fs);
  out2=amp(i).*sin(2*pi*freq(i)*(len_idx-len_idx(1)+1)/Fs+phi(i));
  distortion(i)=sqrt(mean((in(len_idx)-out2).^2))./sqrt(mean(in(len_idx).^2));
  disp(['freq=' num2str(freq(i)) ' Hz;  amp=' num2str(20*log10(amp(i)/stim_amp)+atten) ...
      ' dB;  phi=' num2str(phi(i)) ';  THD+N=' num2str(100*distortion(i)) '%']);
end

delete([ai ao]);

phi=phi-2*rise_fall*2*pi.*freq;

amp=amp./(stim_amp*10.^(-atten/20));  %/sqrt(2)
ambient=ambient./amp./sqrt((Fs/2-1/(2*len))/(Fs*len/2));  %/sqrt(2)

if(~isempty(filename))
  save([filename '_fr'],'freq','chan_out','chan_in','stim_amp','atten','nreps',...
      'amp','phi','ambient','distortion','raw','raw_ambient','Fs');
end

freq_resp_plot(freq,amp,phi,ambient,distortion,raw_ambient,Fs);



function out=cosine_envelope(in,parm1,parm2,Fs)

if((parm1==0) & (parm2==0))
  env=0.5+0.5*cos((1:length(in))./length(in).*2.*pi-pi);
else
  rtmp=floor(parm1*Fs);
  ftmp=floor(parm2*Fs);
  rtmp=0.5+0.5*cos((1:rtmp)./rtmp.*pi-pi);
  ftmp=0.5+0.5*cos((1:ftmp)./ftmp.*pi);
  env=[rtmp ones(1,length(in)-length(rtmp)-length(ftmp)) ftmp];
end
out=in.*env;


% function [amp,phi] = fit_sin(d,f,Fs)
%
% given vector d, frequency f (Hz), and sampling rate Fs (ticks/sec),
% fit a sinewave of frequency f to d and return the amplitude (ticks)
% and phase (radians).
function [amp,phi] = fit_sin(d,f,Fs)

d=squeeze(d);
if(size(d,1)>1)  d=d';  end

d=d-mean(d);

period = Fs/f;
last = floor(period * floor(length(d)/period));

real = mean(d(1:last) .* sin([1:last]*(2*pi/period)));
imag = mean(d(1:last) .* cos([1:last]*(2*pi/period)));

amp = 2*abs(real + i*imag);
phi = angle(real + i*imag);
