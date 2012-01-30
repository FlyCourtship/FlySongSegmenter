%function array_take
%
%array_take is a GUI to a NI-DAQ board, specifically designed to acquire
%multi-channel audio data, simultaneous temperature and humidity data 
%(specifically the SHT7x from sensirion), and video from most any USB/firewire
%camera.
%
%across the top of the window from left to right,
%
%text: the amount of time the display lags the acquisition of data
%text: the temperature and humidity for each of the hygrometers
%button: save data if checked, filenames are date & time stamps
%text: directory to which files are saved
%button: save to .wav files (in addition to .daq)
%field: maximum size in minutes of .wav files, filenames appended with channel and segment number
%menu: interval, in seconds, at which to record temperature and humidity
%menu: maximum range, in volts, of signal input
%field: sampling rate in Hz
%menu: number of channels to record from
%menu: the NI-DAQ board to use
%(button): play a calibration sound while acquiring data
%(button): start / stop data acquisition
%button: exit this program
%
%the three buttons on the right turn on and off three graphical panels.  the
%top is a spectrum, the middle is the raw time trace, and the bottom is a bar
%graph showing the power in each channel (like an equalizer).  the labelled
%buttons across the bottom specify which channel to show in the upper two
%panels.
%
%the()s above indicate optional buttons, depending on the configuration of the
%settings at the top of array_take.m.  the start/stop button can for example
%be replaced with a hardware switch connected to the digital I/O lines, in
%which case the button is not drawn in the window.  parameters at the top of
%array_take.m also specify the characteristics of your particular hardware,
%as well as customize your default preferences.
%
% NOTE: Code has been modified for use with video files great than 2GB in
% sze. To achieve this, MATLAB calls an external instance of a more recent
% version of MATLAB which must also be installed on the computer. The exact
% format of the installed version must be post 2010 and the program ID for
% that version must be entered into the call for 'actxserver' later in
% code. See 'help actxserver'. In this version I am using MATLAB 2011a and
% the program id is: Matlab.Application.7.12. 
%IMPORTANTLY hte modern version of MATLAB installed must also be 32 bit IF
%the dcam driver is being used. Other drivers may have 64 bit support.

%NOTE2: I am using the 'dcam' driver for my camera and the code has been
%written accordingly. It could be modified to use other drivers easily but
%the 'dcam' drive is the most versatile in terms of paramter options for 
%IEEE 1394 cameras. Details on setting up a computer to use this driver 
%can be fount at:
%http://www.mathworks.com/help/toolbox/imaq/f16-75694.html

%NOTE3: Code has also been modified to save files as YYMMDD_HHMM, a
%personal preference.

%version 0.6_Pip

function array_take_Pip

global scale Fs h1 h2 count
global running chan in_port out_port calibrate
global range_settings button_exit button_start_stop button_calib start_stop
global popupmenu_hygro popupmenu_nchan edit_samplerate popupmenu_range popupmenu_daq
global button_fft button_timetrace button_equalizer text_realtime
global button_save text_filedir button_wav edit_filesize text_hygro
global hygro_period hygro_clock hygro_timeout hygro_datain hygro_dataout 
global video vifile video_format video_compress matlab11 fps

%%%% HARDWARE SETTINGS

max_nchan=16;      % maximum number of channels your hardware supports
max_Fs=250e3;      % maximum aggregate sampling frequency your hardware supports, in Hz
range_settings=[10 5 1 0.2];   % available scales your hardware supports, in V
start_stop=-1;     % -1 = use software start/stop button
                   % >0 = hardware switch on this digital line
calibrate=1;       % 1 = optionally play calibration sound while recording
                   % 0 = no such button
                   % can be broadband noise or a harmonic stack, see line 374
hygro_clock=0;     % the digital output line connected to the SHT7x's SCK line
hygro_dataout=1;   % the digital output line connected to the SHT7x's DATA line
hygro_datain=1;    % the digital input line(s) connected to the SHT7x's DATA line
in_port=0;         % which hardware port is used for digital input
out_port=1;        % which hardware port is used for digital output
video = 1;           % camera attached?, 1=yes, 0=no
fps = 30;          %Which framerate should be captured (options will depend on camera)
video_format='Y8_640x480';  %Which video format should be captured (options will depend on camera)
video_compress='Motion JPEG AVI'; %Type of video compression - see 'help VideoWriter'

%%%% SOFTWARE SETTINGS

nchan_init = 9;
samplerate_init= 10000;   %max_Fs/max_nchan;%10000
range_init=1;      % i.e. range_settings(range_init)
hygro_init=1;      % time btw measurements, 1 = 30s, 2 = 60s, 3 = 120s, etc.
wav_init=0;        % 1 = save as separated .wav files in addition to .daq
wav_size_init=2;   % max length in minutes for each .wav file.  0 = unlimited
window_size=1.5;   % scale factor from default window size, must be >=1.5

%%%% SHOULDN'T NEED TO CHANGE THESE

hygro_clockperiod=0.001;
hygro_timeout=3;
scale=1;
chan=1;
count=1024;



h=figure;
foo=get(h,'Position');
set(h,'Position',round([400 250 window_size*foo(3) window_size*foo(4)]));
tmp=get(gcf,'position');  tmp2=get(gcf,'color');

text_realtime=uicontrol('style','text',...
   'backgroundColor',tmp2,'position',[5 tmp(4)-24 30 18]);
for(i=1:length(hygro_datain))
  text_hygro(i)=uicontrol('style','text',...
     'backgroundColor',tmp2,'position',[40+65*(i-1) tmp(4)-24 60 18]);
end
button_save=uicontrol('style','radiobutton','value',0,...
   'backgroundColor',tmp2,...
   'position',[40+65*length(hygro_datain) tmp(4)-24 20 20],...
   'callback',['global button_save text_filedir button_wav edit_filesize;'...
               'if(get(button_save,''value''))'...
               '  set(text_filedir,''string'',uigetdir);'...
               '  set(text_filedir,''enable'',''on'');'...
               '  set(button_wav,''enable'',''on'');'...
               '  if(get(button_wav,''value''))'...
               '    set(edit_filesize,''enable'',''on'');'...
               '  else'...
               '    set(edit_filesize,''enable'',''off'');'...
               '  end;'...
               'else'...
               '  set(text_filedir,''enable'',''off'');'...
               '  set(button_wav,''enable'',''off'');'...
               '  set(edit_filesize,''enable'',''off'');'...
               'end']);
text_filedir=uicontrol('style','text',...
   'backgroundColor',tmp2,...
   'position',[60+65*length(hygro_datain) tmp(4)-32 tmp(3)-575 30]);
button_wav=uicontrol('style','radiobutton','value',wav_init,'enable','off',...
   'backgroundColor',tmp2,...
   'position',[tmp(3)-335-45*(start_stop==-1)-20*calibrate tmp(4)-24 20 20],...
   'callback',['global button_wav edit_filesize;'...
               'if(get(button_wav,''value''))'...
               '  set(edit_filesize,''enable'',''on'');'...
               'else'...
               '  set(edit_filesize,''enable'',''off'');'...
               'end']);
edit_filesize=uicontrol('style','edit','string',wav_size_init,...
   'position',[tmp(3)-315-45*(start_stop==-1)-20*calibrate tmp(4)-24 20 22]);
set(edit_filesize,'enable','off');
popupmenu_hygro=uicontrol('style','popupmenu','value',hygro_init,...
   'string',60*2.^(-1:4),...
   'position',[tmp(3)-290-45*(start_stop==-1)-20*calibrate tmp(4)-24 45 22],...
   'callback', @array_init);
popupmenu_range=uicontrol('style','popupmenu','value',range_init,...
   'string',range_settings,...
   'position',[tmp(3)-240-45*(start_stop==-1)-20*calibrate tmp(4)-24 40 22],...
   'callback', @array_init);
edit_samplerate=uicontrol('style','edit','string',samplerate_init,...
   'position',[tmp(3)-195-45*(start_stop==-1)-20*calibrate tmp(4)-24 50 22]);
popupmenu_nchan=uicontrol('style','popupmenu','value',nchan_init,...
   'string',[1:max_nchan],...
   'position',[tmp(3)-140-45*(start_stop==-1)-20*calibrate tmp(4)-24 35 22],...
   'callback', @array_init);
popupmenu_daq=uicontrol('style','popupmenu','value',1,...
   'string',daqhwinfo('nidaq','InstalledBoardIds'),...
   'position',[tmp(3)-100-45*(start_stop==-1)-20*calibrate tmp(4)-24 50 22],...
   'callback', @array_init);
if(calibrate)
  button_calib=uicontrol('style','radiobutton','value',0,...
     'backgroundColor',tmp2,...
     'position',[tmp(3)-65-45*(start_stop==-1) tmp(4)-24 20 20],...
     'callback', @array_init);
end
if(start_stop==-1)
  button_start_stop=uicontrol('style','pushbutton','backgroundColor',[0 1 0],...
     'string','start',...
     'position',[tmp(3)-90 tmp(4)-24 40 22],...
     'callback', @array_start_stop_cbk);
end
button_exit=uicontrol('style','pushbutton',...
   'backgroundColor',tmp2,...
   'string','exit',...
   'position',[tmp(3)-45 tmp(4)-24 40 22],...
   'callback',['global ai ao dio vi;'...
               'delete([ai ao]); delete(vi); stop(dio); delete(dio); close all; clear all;']);

button_fft=uicontrol('style','radiobutton',...
   'backgroundColor',tmp2,'position',[tmp(3)-30 tmp(4)-window_size*80 20 20],...
   'callback', @button_fft_cbk);
button_timetrace=uicontrol('style','radiobutton',...
   'backgroundColor',tmp2,'position',[tmp(3)-30 tmp(4)-window_size*210 20 20],...
   'callback', @button_timetrace_cbk);
button_equalizer=uicontrol('style','radiobutton',...
   'backgroundColor',tmp2,'position',[tmp(3)-30 tmp(4)-window_size*360 20 20]);

button_scale_bigger=uicontrol('style','pushbutton','value',scale,...
   'string','^','backgroundColor',tmp2,'position',[tmp(3)-33 tmp(4)-window_size*190 20 20],...
   'callback', 'global scale h1;  scale=scale*2;  subplot(4,1,3);  cla;  h1=[];');
button_scale_smaller=uicontrol('style','pushbutton','value',scale,...
   'string','v','backgroundColor',tmp2,'position',[tmp(3)-33 tmp(4)-window_size*230 20 20],...
   'callback', 'global scale h1;  scale=scale/2;  subplot(4,1,3);  cla;  h1=[];');

array_init;



function button_fft_cbk(varargin)

global button_spectrogram h2;
if(get(button_spectrogram,'value'))
  subplot(3,1,1);  cla;  h2=[];
end;



function button_timetrace_cbk(varargin)

global button_timetrace h1;
if(get(button_timetrace,'value'))
  subplot(3,1,2);  cla;  h1=[];
end;



function array_init(obj,event)

global Fs range_settings count start_stop in_port out_port calibrate video
global popupmenu_hygro popupmenu_nchan edit_samplerate popupmenu_range 
global popupmenu_daq button_calib buttons_chan
global hygro_period hygro_datain hygro_dataout hygro_clock
global running ai ao dio vi video_format matlab11 fps

if(~isempty(ai))  delete(ai);  end
if(~isempty(ao))  delete(ao);  end
if(~isempty(dio))  delete(dio);  end
if(~isempty(buttons_chan))  delete(buttons_chan);  end

Fs=str2num(get(edit_samplerate,'string'));
nchan=get(popupmenu_nchan,'value');
hygro_period=60*2^(get(popupmenu_hygro,'value')-2);
range=range_settings(get(popupmenu_range,'value'));
daq=daqhwinfo('nidaq','InstalledBoardIds');
daq=char(daq(get(popupmenu_daq,'value')));

ai = analoginput('nidaq',daq);
set(ai,'InputType','NonReferencedSingleEnded');
for(i=0:nchan-1)
  tmp=addchannel(ai,i);
  set(tmp,'InputRange',[-range range]);
end
set(ai,'SampleRate',Fs);
set(ai,'SamplesPerTrigger',inf)
set(ai,'SamplesAcquiredFcn',{@array_plot_data})
set(ai,'SamplesAcquiredFcnCount',count)
set(ai,'TriggerType','Manual')
%set(ai,'ExternalTriggerDriveLine','PFI7');

if(calibrate && get(button_calib,'value'))
  ao = analogoutput('nidaq',daq);
  ao.TriggerType = 'Manual';
  %ao.TriggerType = 'HwDigital';
  %ao.HwDigitalTriggerSource = 'PFI3';
  ao.SampleRate=Fs;
  ao.RepeatOutput=8;
  addchannel(ao,0);
  addchannel(ao,1);
end

dio = digitalio('nidaq',daq);
if(start_stop>-1)
  addline(dio,start_stop,in_port,'in','StartStop');
end
addline(dio,hygro_clock,out_port,'out','HygroClk');
addline(dio,hygro_dataout,out_port,'out','HygroOut');
addline(dio,hygro_datain,in_port,'in','HygroIn');

running=0;
if(start_stop>-1)
  set(dio,'TimerFcn',{@array_start_stop_cbk});
end
start(dio);

buttons_chan=uibuttongroup('unit','pixels','position',[0 0 1 1],...
   'SelectionChangeFcn',@selcbk);
tmp=get(gcf,'position');  tmp2=get(gcf,'color');
for(i=0:nchan-1)
  uicontrol('parent',buttons_chan,'style','radiobutton','string',i+1,...
     'backgroundColor',tmp2,...
     'position',[0.05*tmp(3)+0.9*(i+1)*tmp(3)/(nchan+1) 2 40 20]);
end

if(video)
    matlab11 = actxserver('Matlab.Application.7.12');
    matlab11.PutWorkspaceData('video_format', 'base', video_format);
    matlab11.PutWorkspaceData('fps', 'base', fps);
    invoke(matlab11, 'Execute', [...
        'vi=videoinput(''dcam'',1,video_format);'...
        'triggerconfig(vi,''manual'');'...
        'set(vi,''FramesPerTrigger'',Inf);'...
        'viParam = getselectedsource(vi);'...
        'viParam.FrameRate = num2str(fps);'...
        'viParam.shutter = 450;'...
        'viParam.gain = 1250']);
    invoke(matlab11, 'Execute', 'preview(vi)');
%   triggerconfig(vi,'manual');
%   set(vi,'FramesPerTrigger',Inf);
end



function selcbk(source,eventdata)

global chan

chan=str2num(get(eventdata.NewValue,'string'));




function array_start_stop_cbk(obj,event)

global Fs range_settings start_stop calibrate video matlab11
global running button_exit button_start_stop button_calib
global popupmenu_hygro popupmenu_nchan edit_samplerate popupmenu_range 
global popupmenu_daq button_save text_filedir button_wav edit_filesize
global ai ao dio vi vifile video_compress filename t hygro_period fps

if(running && (start_stop==-1 || ~getvalue(dio.StartStop)))
  running=0;
  if(calibrate && get(button_calib,'value'))
    stop([ai ao]);  if(video) invoke(matlab11, 'Execute', 'stop([vi])'); end
  else
    stop([ai]);  if(video) invoke(matlab11, 'Execute', 'stop([vi])'); end
  end
  if((video) && get(button_save,'value'))
    DiskLoggerFrameCount = 1; FramesAcquired = 0;
    while(DiskLoggerFrameCount~=FramesAcquired)
      pause(1);
      invoke(matlab11, 'Execute', ['DiskLoggerFrameCount = '...
          'vi.DiskLoggerFrameCount; FramesAcquired = vi.FramesAcquired;']);
      FramesAcquired = ...
          matlab11.GetVariable('FramesAcquired','base');
      DiskLoggerFrameCount = ...
          matlab11.GetVariable('DiskLoggerFrameCount','base');
    end
    invoke(matlab11, 'Execute', 'vifile=close(vi.DiskLogger)');
  end
  if(get(button_save,'value') && get(button_wav,'value'))
    file=[get(text_filedir,'string') '\' filename];
    dinfo=daqread([file '.daq'],'info');
    fsize=get(edit_filesize,'string');
    if(~isempty(fsize))
      fsize=round(str2num(fsize)*60*Fs);
    else
      fsize=dinfo.ObjInfo.SamplesAcquired;
    end
    range=range_settings(get(popupmenu_range,'value'));
    for(i=1:length(dinfo.ObjInfo.Channel))
      for(j=1:fsize:dinfo.ObjInfo.SamplesAcquired)
        d=daqread([file '.daq'],'Channels',i,...
            'Samples',[j min(j+fsize-1,dinfo.ObjInfo.SamplesAcquired)]);
        d=d./range;
        wavwrite(d,Fs,16,...
            [file '.' num2str(i) '.' num2str(1+round((j-1)/fsize)) '.wav']);
      end
    end
  end
  set(button_exit,'enable','on');
  if(start_stop==-1)
    set(button_start_stop,'string','start','backgroundColor',[0 1 0]);
  end
  if(calibrate)  set(button_calib,'enable','on');  end
  set(popupmenu_daq,'enable','on');
  set(popupmenu_nchan,'enable','on');
  set(edit_samplerate,'enable','on');
  set(popupmenu_range,'enable','on');
  set(popupmenu_hygro,'enable','on');
  if(get(button_save,'value'))
    set(button_wav,'enable','on');
    if(get(button_wav,'value'))
      set(edit_filesize,'enable','on');
    end
  end
  set(text_filedir,'enable','on');
  set(button_save,'enable','on');
  stop(t);
  delete(t);
  
elseif(~running && (start_stop==-1 || getvalue(dio.StartStop)))
  if(get(button_save,'value'))
    filename=sprintf('%02d',round(clock'));
    filename = [filename(3:8) '_' filename(9:12)];
    set(ai,'LogFileName',[get(text_filedir,'string') '\' filename '.daq']);
    set(ai,'LoggingMode','Disk&Memory');
    if(video)
      matlab11.PutWorkspaceData('vidname', 'base', ...
        [get(text_filedir,'string') '\' filename]);
      matlab11.PutWorkspaceData('video_compress', 'base', video_compress);
      invoke(matlab11,'Execute', 'set(vi,''LoggingMode'',''disk'')');
      invoke(matlab11, 'Execute', ['vifile=VideoWriter(vidname,'...
          'video_compress); vifile.FrameRate = fps;']);
      invoke(matlab11,'Execute', 'set(vi,''DiskLogger'', vifile)');
    end
  else
    filename=[];
    set(ai,'LoggingMode','Memory');
    if(video)
      invoke(matlab11,'Execute', 'set(vi,''DiskLogger'', [])');
    end
  end
  running=1;
  if(calibrate && get(button_calib,'value'))
    len=1;  isi=5;
    if(1)  %  noise
      tmp=random('unif',-1,ones(1,round(len*Fs)));
      [b,a]=butter(1,4000/(Fs/2));  tmp=filtfilt(b,a,tmp);
      [b,a]=butter(4,7500/(Fs/2));  tmp=filtfilt(b,a,tmp);
      tmp=10.*tmp./(max(abs(tmp))+eps);
      tmp=[zeros(1,length(tmp)); tmp];
    else   %  stack
      tmp=zeros(2,round(len*Fs));
      for(j=1:2)
        for(i=[800:800:7000; 900:900:8000])
          tmp(j,:)=tmp(j,:)+sin(2*pi*i(j)*(1:round(len*Fs))./Fs+2*pi*rand(1));
        end
      end
      tmp=3.*tmp./max(reshape(tmp,1,prod(size(tmp))));
    end
    putdata(ao,[zeros(2,round(isi*Fs)) tmp]');

    start([ai ao]);  
    if(video) invoke(matlab11, 'Execute', 'start(vi)'); end
    trigger([ai ao]);  
    if(video) invoke(matlab11, 'Execute', 'trigger([vi])'); end
  else
    start(ai);  
    if(video) invoke(matlab11, 'Execute', 'start(vi)'); end
    trigger([ai]);  
    if(video) invoke(matlab11, 'Execute', 'trigger([vi])'); end
  end
  set(button_exit,'enable','off');
  if(start_stop==-1)
    set(button_start_stop,'string','stop','backgroundColor',[1 0 0]);
  end
  if(calibrate)  set(button_calib,'enable','off');  end
  set(popupmenu_daq,'enable','off');
  set(popupmenu_nchan,'enable','off');
  set(edit_samplerate,'enable','off');
  set(popupmenu_range,'enable','off');
  set(popupmenu_hygro,'enable','off');
  set(button_wav,'enable','off');
  set(edit_filesize,'enable','off');
  set(text_filedir,'enable','off');
  set(button_save,'enable','off');
  
  t=timer;
  set(t,'Name','hygrometer');
  set(t,'Period',hygro_period);
  set(t,'ExecutionMode','fixedRate');
  set(t,'TimerFcn',@array_hygro);
  start(t);
end




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




function array_hygro(obj,event)

global ai button_save text_filedir filename text_hygro

transmission_start=[0 1 1 0 1 1 0 0;
                    1 1 0 0 0 1 1 0];
measure_temp=[1 0 1 0 1 0 1 0 1 0 1 0 0 1 0 1 0;
              0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1];
measure_RH  =[1 0 1 0 1 0 1 0 1 0 0 1 0 0 1 0 0 1 0;
              0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 1 1 1];

err=1;
while(err)
  hygro_write(transmission_start);
  hygro_write(measure_temp);
  err=hygro_wait_ack();
end
T=hygro_read();
T=-40.1+0.01.*T;  % 5V, 14-bit
%disp(['T=' num2str(T)]);

err=1;
while(err)
  hygro_write(transmission_start);
  hygro_write(measure_RH);
  err=hygro_wait_ack();
end
RH=hygro_read();
tmp=-2.0468+0.0367.*RH-1.5955e-6.*RH.^2;
RH=(T-25).*(0.01+0.00008.*RH)+tmp;
%disp(['RH=' num2str(RH)]);

for(i=1:length(T))
  set(text_hygro(i),'string',[num2str(T(i),'%2.1f') 'C,' num2str(RH(i),2) '%']);
end

if(get(button_save,'value'))
  fid=fopen([get(text_filedir,'string') '\' filename '.hyg'],'a');
  fprintf(fid,'%f ',etime(clock,get(ai,'InitialTriggerTime')));
  fprintf(fid,'%f ',T);
  fprintf(fid,'%f ',RH);
  fprintf(fid,'\n');
  fclose(fid);
end



function hygro_write(data)

global dio hygro_clockperiod

for(i=1:size(data,2))
  putvalue([dio.HygroClk dio.HygroOut],[data(1,i) ~data(2,i)]);
  pause(hygro_clockperiod);
end



function err=hygro_wait_ack()

global dio hygro_clockperiod  hygro_timeout  hygro_datain

tic;
while((sum(getvalue(dio.HygroIn))>0) && (toc<hygro_timeout))  end
if(sum(getvalue(dio.HygroIn))>0)
  disp('hygro timed out 1');
  putvalue(dio.HygroOut,~1);
  for(i=1:10)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  err=1;
  return;
end
putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
putvalue(dio.HygroClk,0);  pause(0.1);
tic;
while((sum(getvalue(dio.HygroIn))>0) && (toc<hygro_timeout))  end
if(sum(getvalue(dio.HygroIn)>0))
  disp('hygro timed out 2');
  putvalue(dio.HygroOut,~1);
  for(i=1:10)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  err=1;
  return;
end
err=0;



function ret_val=hygro_read()

global dio hygro_clockperiod  hygro_datain

idx=4:3+length(hygro_datain);

tmp=zeros(length(hygro_datain),2);
for(i=1:2)
  for(j=7:-1:0)
    putvalue(dio.HygroClk,1);  pause(hygro_clockperiod);
    tmp(:,i)=tmp(:,i)+(2^j).*getvalue(dio.HygroIn)';
    putvalue(dio.HygroClk,0);  pause(hygro_clockperiod);
  end
  if(i==1)
    putvalue(dio.HygroOut,~0);  pause(hygro_clockperiod);
  end
  putvalue(dio.HygroClk,1);   pause(hygro_clockperiod);
  putvalue(dio.HygroClk,0);   pause(hygro_clockperiod);
  putvalue(dio.HygroOut,~1);  pause(hygro_clockperiod);
end

ret_val=256*tmp(:,1)+tmp(:,2);
ret_val=ret_val';
