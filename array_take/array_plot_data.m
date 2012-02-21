function array_plot_data(obj,event)

global scale Fs save chan h1 count range_settings
global ai running button_start_stop popupmenu_nchan popupmenu_range
global button_fft button_timetrace button_equalizer text_realtime buttons_chan

nchan=get(popupmenu_nchan,'value');
range=range_settings(get(popupmenu_range,'value'));

[d t]=getdata(ai,count);

if(get(button_fft,'value')==1)
subplot(3,1,1);
[pxx f]=pwelch(d(:,chan)',[],[],[],Fs);
plot(f,20*log10(pxx));
xlabel('frequency (Hz)');
ylabel('intensity (dB)');
axis tight;
end

if(get(button_timetrace,'value')==1)
if(isempty(h1))
  h1=nan*zeros(1,round(scale/(count/Fs)));
end
h1=circshift(h1,[0 -1]);
if(~isnan(h1(1,end)))
  delete(h1(1,end));
end
subplot(3,1,2);  hold on;
h1(1,end)=plot(t,d(:,chan));
axis([t(end)-scale t(end) -range +range]);
xlabel('time (s)');
ylabel('intensity (V)');
end

if(get(button_equalizer,'value')==1)
subplot(3,1,3);
tmp=[];
for(i=1:nchan)
  foo=mean(d(:,i));
  tmp(i)=sqrt(mean((d(:,i)-foo).^2));
end
bar(1:nchan,tmp);
%axis off
end

tmp=get(ai,'SamplesAvailable');
%tmp2=get(ai,'SamplesAcquired');
set(text_realtime,'string',[num2str(tmp/Fs,'%2.1f') 's']);
%set(text_realtime,'string',num2str((tmp2-tmp)/tmp2,2));

drawnow;
