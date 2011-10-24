%function flysong_segmenter_byhand3(file)
%function flysong_segmenter_byhand3(data,Fs)
%
%file is the .daq output filename of array_take
%data is a matrix containing the data from daqread()
%Fs is the sampling rate
%
%popupmenu on the left selects the channel number
%pan with < and >, zoom with + and -
%add multiple pulses by clicking on each and then pressing the return key (PULSE_MODE=1)
%add a pulse by clicking on the peak and trough (PULSE_MODE=2)
%add a sine song by clicking on the beginning and end
%delete removes just those currently displayed
%save creates a .mat file with _byhand appended to filename
%  if workspace data passed in, file is workspace_byhand.mat
%
%ver 0.2:
%  now loads in old byhand.mat files if they exist for further editing
%  supports passing in workspace variables
%  pulses delineated by either peak and trough, or just peak
%  can now listen to data too
%
%ver 0.3:
%  now resizes gracefully
%  added PULSE_MODE
%  added keyboard shortcuts (p = add pulse song, s = add sine song, etc)
%  added confirmation dialog for delete of N>10 items
%  toggle y-axis scale option
%  added sonogram
%
%to convert PULSE_MODE=1 _byhand.mat files to PULSE_MODE=2, rename them to
% _old.mat, load them, and then PULSE=[PULSE PULSE(:,2)+0.001]; and then
% save() without _old;

function flysong_segmenter_byhand3(varargin)

global RAW IDXP IDXS PAN ZOOM
global CHANNEL FILE DATA PULSE SINE PULSE_MODE YSCALE NFFT
global FS NARGIN H

PULSE_MODE=2;

IDXP=[];
IDXS=[];
M=[];
TOGGLE=[];
PAN=0;  % ms
ZOOM=100;  % ms
SHIFT=max(RAW)-min(RAW);
EDIT=0;
STEP_SIZE=1;
DELETE_BUTTON=[];
CHANNEL=1;
NARGIN=nargin;
NFFT=2^9;

if(NARGIN==1)
  VARARGOUT=[];
  if(strcmp(varargin{1}(end-3:end),'.daq'))
    FILE=varargin{1}(1:end-4);
  else
    FILE=varargin{1};
  end

  if(exist([FILE '_byhand.mat'],'file'))
    load([FILE '_byhand.mat']);
  else
    PULSE=[];
    SINE=[];
  end

  dinfo=daqread(FILE,'info');
  NCHAN=length(dinfo.ObjInfo.Channel);
  FS=dinfo.ObjInfo.SampleRate;
  RAW=daqread(FILE,'Channel',CHANNEL);
else
  PULSE=[];
  SINE=[];
  DATA=varargin{1};
  NCHAN=size(DATA,2);
  FS=varargin{2};
  RAW=DATA(:,CHANNEL);
end

YSCALE=max(max(RAW));
if(PAN>length(RAW)/FS*1000) PAN=0; end
if((PAN+ZOOM)>(length(RAW)/FS*1000)) ZOOM=(length(RAW)/FS*1000)-PAN; end

figure;
tmp=get(gcf,'position');
set(gcf,'position',[0 0 1.5*tmp(3) 1.5*tmp(4)]);
set(gcf,'menubar','none','ResizeFcn',@resizeFcn,'WindowKeyPressFcn',@windowkeypressFcn);

H=uipanel();
uicontrol('parent',H,'style','popupmenu','value',CHANNEL,...
   'string',1:NCHAN, ...
   'callback', @changechannel_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','<','tooltipstring','pan left', ...
   'callback', @panleft_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','^','tooltipstring','zoom in', ...
   'callback', @zoomin_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','v','tooltipstring','zoom out', ...
   'callback', @zoomout_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','>','tooltipstring','pan right', ...
   'callback', @panright_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(y)scale','tooltipstring','toggle y-scale', ...
   'callback', @yscale_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(f)req','tooltipstring','increase frequency resolution', ...
   'callback', @nfftup_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(t)ime','tooltipstring','increase temporal resolution', ...
   'callback', @nfftdown_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(p)ulse','tooltipstring','add pulse song', ...
   'callback', @addpulse_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(s)ine','tooltipstring','add sine song', ...
   'callback', @addsine_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(d)elete','tooltipstring','delete displayed pulse and sine song', ...
   'callback', @delete_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(l)isten','tooltipstring','listen to displayed recording', ...
   'callback', @listen_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','save','tooltipstring','save segmentation to disk', ...
   'callback', @save_callback);

update;


function resizeFcn(src,evt)

global H

tmp=get(gcf,'position');
foo=get(H,'children');

for(i=1:length(foo))
  switch(get(foo(i),'string'))
    case('<')
      set(foo(i),'position',[80,tmp(4)-30,20,20]);
    case('^')
      set(foo(i),'position',[100,tmp(4)-30,20,20]);
    case('v')
      set(foo(i),'position',[120,tmp(4)-30,20,20]);
    case('>')
      set(foo(i),'position',[140,tmp(4)-30,20,20]);
    case('(y)scale')
      set(foo(i),'position',[160,tmp(4)-30,50,20]);
    case('(f)req')
      set(foo(i),'position',[210,tmp(4)-30,40,20]);
    case('(t)ime')
      set(foo(i),'position',[250,tmp(4)-30,40,20]);
    case('(p)ulse')
      set(foo(i),'position',[290,tmp(4)-30,50,20]);
    case('(s)ine')
      set(foo(i),'position',[340,tmp(4)-30,50,20]);
    case('(d)elete')
      set(foo(i),'position',[390,tmp(4)-30,50,20]);
    case('(l)isten')
      set(foo(i),'position',[440,tmp(4)-30,50,20]);
    case('save')
      set(foo(i),'position',[490,tmp(4)-30,40,20]);
    otherwise
      set(foo(i),'position',[20,tmp(4)-30,50,20]);
  end
end


function windowkeypressFcn(src,evt)

switch(evt.Key)
  case('leftarrow')
    panleft_callback;
  case('uparrow')
    zoomin_callback;
  case('downarrow')
    zoomout_callback;
  case('rightarrow')
    panright_callback;
  case('y')
    yscale_callback;
  case('f')
    nfftup_callback;
  case('t')
    nfftdown_callback;
  case('p')
    addpulse_callback;
  case('s')
    addsine_callback;
  case('d')
    delete_callback;
  case('l')
    listen_callback;
end



function changechannel_callback(hObject,eventdata)

global FILE DATA RAW CHANNEL PAN ZOOM NARGIN

CHANNEL=get(hObject,'value');
if(NARGIN==1)
  RAW=daqread(FILE,'Channel',CHANNEL);
else
  RAW=DATA(:,CHANNEL);
end
update;



function panleft_callback(hObject,eventdata)

global PAN ZOOM;
PAN=max(0,PAN-ZOOM/2);
update;



function zoomin_callback(hObject,eventdata)

global PAN ZOOM;

if(ZOOM<10)  return;  end;
ZOOM=ZOOM/2;
PAN=PAN+ZOOM/2;
update;



function zoomout_callback(hObject,eventdata)

global PAN ZOOM RAW FS;

PAN=max(0,PAN-ZOOM/2);
ZOOM=ZOOM*2;
if((PAN+ZOOM)>(length(RAW)/FS*1000))
  ZOOM=(length(RAW)/FS*1000)-PAN;
end
update;



function panright_callback(hObject,eventdata)

global PAN ZOOM RAW FS;

PAN=min(length(RAW)/FS*1000-ZOOM,PAN+ZOOM/2);
update;



function addpulse_callback(hObject,eventdata)

global CHANNEL PULSE PULSE_MODE;

if(PULSE_MODE==1)
  tmp=ginput;
  tmp2=size(tmp,1);
  PULSE(end+1:end+tmp2,:)=[repmat(CHANNEL,tmp2,1) tmp(:,1)];
else
  tmp=ginput(2);
  PULSE(end+1,:)=[CHANNEL tmp(:,1)'];
end
update;



function addsine_callback(hObject,eventdata)

global CHANNEL SINE;

tmp=ginput(2);
SINE(end+1,:)=[CHANNEL tmp(:,1)'];
update;



function delete_callback(hObject,eventdata)

global PULSE SINE IDXP IDXS;

tmpp=setdiff(1:size(PULSE,1),IDXP);
tmps=setdiff(1:size(SINE,1),IDXS);
foo='yes';
bar=length(IDXP)+length(IDXS);
if(bar>10)
   foo=questdlg(['are you sure you want to delete these ' num2str(bar) ' items?'],...
       '','yes','no','no');
end
if(strcmp(foo,'yes'))
  PULSE=PULSE(tmpp,:);
  SINE=SINE(tmps,:);
end
update;



function listen_callback(hObject,eventdata)

global RAW PAN ZOOM FS;

sound(RAW((1+ceil(PAN/1000*FS)):floor((PAN+ZOOM)/1000*FS)),FS);



function save_callback(hObject,eventdata)

global FILE PULSE SINE NARGIN VARARGOUT;

if(NARGIN==1)
  save([FILE '_byhand.mat'],'PULSE','SINE');
else
  save(['workspace_byhand.mat'],'PULSE','SINE');
end


function yscale_callback(hObject,eventdata)

global YSCALE

YSCALE=-YSCALE;
update;


function nfftup_callback(hObject,eventdata)

global NFFT

NFFT=NFFT*2;
update;


function nfftdown_callback(hObject,eventdata)

global NFFT

NFFT=NFFT/2;
update;


function update

global RAW IDXP IDXS PAN ZOOM 
global CHANNEL FILE PULSE SINE PULSE_MODE YSCALE NFFT
global FS

foo2=(1+ceil(PAN/1000*FS)):floor((PAN+ZOOM)/1000*FS);
foo=RAW(foo2);

subplot(2,1,1);  cla;  hold on;
if(length(foo)>NFFT)
  [s,f,t,p]=spectrogram(foo',NFFT,[],[],FS,'yaxis');
  fidx=find(f>=25 & f<=2500);
  surf((t+foo2(1)./FS).*1000,f(fidx),log10(abs(p(fidx,:))),'EdgeColor','none');
  colormap(flipud(gray));
  axis tight;
  ylabel('frequency (Hz)');
end

subplot(2,1,2);  cla;  hold on;

IDXP=[];
if(~isempty(PULSE))
  if(PULSE_MODE==1)
    IDXP=find((PULSE(:,1)==CHANNEL) & ...
           (((PULSE(:,2)>=PAN) & (PULSE(:,2)<=(PAN+ZOOM)))));
  else
    IDXP=find((PULSE(:,1)==CHANNEL) & ...
           (((PULSE(:,2)>=PAN) & (PULSE(:,2)<=(PAN+ZOOM))) | ...
            ((PULSE(:,3)>=PAN) & (PULSE(:,3)<=(PAN+ZOOM)))));
  end
end

IDXS=[];
if(~isempty(SINE))
  IDXS=find((SINE(:,1)==CHANNEL) & ...
           (((SINE(:,2)>=PAN) & (SINE(:,2)<=(PAN+ZOOM))) | ...
            ((SINE(:,3)>=PAN) & (SINE(:,3)<=(PAN+ZOOM)))));
end

for(i=1:length(IDXP))
  if(PULSE_MODE==1)
    plot([PULSE(IDXP(i),2) PULSE(IDXP(i),2)],[min(foo) max(foo)],...
          'b-','linewidth',3);
  else
    patch([PULSE(IDXP(i),2) PULSE(IDXP(i),2) PULSE(IDXP(i),3) PULSE(IDXP(i),3)],...
          [min(foo)  max(foo)  max(foo)  min(foo)],...
          'b','EdgeColor','b');
  end
end
for(i=1:length(IDXS))
  patch([SINE(IDXS(i),2) SINE(IDXS(i),2) SINE(IDXS(i),3) SINE(IDXS(i),3)],...
        [min(foo)  max(foo)  max(foo)  min(foo)],...
        'r','EdgeColor','r');
end
plot(foo2./FS.*1000,foo,'k');

axis tight;
if(YSCALE<0)
    v=axis;
    axis([foo2(1)./FS.*1000 foo2(end)./FS.*1000 v(3) v(4)]);
else
    axis([foo2(1)./FS.*1000 foo2(end)./FS.*1000 -YSCALE YSCALE]);
end
xlabel('time (ms)');

v=axis;
subplot(2,1,1);
vv=axis;
axis([v(1) v(2) vv(3) vv(4)]);
