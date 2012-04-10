%function flysong_segmenter_byhand5(file)
%function flysong_segmenter_byhand5(data,Fs)
%
%file is the .daq output filename of array_take
%data is a matrix containing the data from daqread()
%Fs is the sampling rate
%
%popupmenu on the left selects the channel number
%pan with < and >, zoom with ^ and v
%add multiple pulses by clicking on each and then pressing
%  the return key (PULSE_MODE=1)
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
%ver 0.4:
%  increased contrast of spectrum by clipping extreme 1%s
%  bispectrum!
%  F-test!!
%
%ver 0.5:
%  better control for y-axis zoom with shift arrow keys
%  x-scale units now parameterized in UNITS{}
%  parfor for F-test
%  time/frequency resolutions displayed (and NW-K for multi-taper)
%
%to convert PULSE_MODE=1 _byhand.mat files to PULSE_MODE=2, rename them to
% _old.mat, load them, and then PULSE=[PULSE PULSE(:,2)+0.001]; and then
% save() without _old;

function flysong_segmenter_byhand5(varargin)

global RAW IDXP IDXS XPAN XZOOM YPAN YZOOM UNITS
global CHANNEL FILE DATA PULSE SINE PULSE_MODE NFFT
global FS NARGIN H BISPECTRUM FTEST PARAMS NW K TEXT

%UNITS{1}=1000;
%UNITS{2}='ms';
UNITS{1}=1;
UNITS{2}='s';

PULSE_MODE=2;

IDXP=[];
IDXS=[];
M=[];
TOGGLE=[];
XPAN=0;
XZOOM=0.1;
SHIFT=max(RAW)-min(RAW);
EDIT=0;
STEP_SIZE=1;
DELETE_BUTTON=[];
CHANNEL=1;
NARGIN=nargin;
NFFT=2^9;
BISPECTRUM=0;
FTEST=0;
NW=9;  K=17;

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

YPAN=0;
YZOOM=FS/2;

if(XPAN>length(RAW)/FS) XPAN=0; end
if((XPAN+XZOOM)>(length(RAW)/FS)) XZOOM=(length(RAW)/FS)-XPAN; end

figure;
tmp=get(gcf,'position');
set(gcf,'position',[0 0 1.5*tmp(3) 1.5*tmp(4)]);
set(gcf,'menubar','none','ResizeFcn',@resizeFcn,'WindowKeyPressFcn',@windowkeypressFcn);

H=uipanel();
uicontrol('parent',H,'style','popupmenu','value',CHANNEL,...
   'string',1:NCHAN, ...
   'callback', @changechannel_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','<','tooltipstring','pan X left; right click is zoom Y out', ...
   'callback', @panleft_callback, ...
   'buttondownfcn', @yzoomout_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','^','tooltipstring','zoom X in;  right click is pan Y up', ...
   'callback', @xzoomin_callback,...
   'buttondownfcn', @panup_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','v','tooltipstring','zoom X out;  right click is pan Y down', ...
   'callback', @xzoomout_callback,...
   'buttondownfcn', @pandown_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','>','tooltipstring','pan X right;  right click is zoom Y in', ...
   'callback', @panright_callback,...
   'buttondownfcn', @yzoomin_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(f)req','tooltipstring','increase frequency resolution', ...
   'callback', @nfftup_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(t)ime','tooltipstring','increase temporal resolution', ...
   'callback', @nfftdown_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(b)ispectrum','tooltipstring','toggle between spectrum and bispectrum', ...
   'callback', @bispectrum_callback);
uicontrol('parent',H,'style','pushbutton',...
   'string','(m)ulti-taper F-test','tooltipstring','toggle between spectrum and multi-taper spectrum with F-test', ...
   'callback', @ftest_callback);
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
TEXT=uicontrol('parent',H,'style','text',...
   'horizontalalignment','left',...
   'tooltip','time and frequency resolution of FFT (and time-bandwidth product and # of tapers for F-test)');

update;


function resizeFcn(src,evt)

global H

tmp=get(gcf,'position');
foo=get(H,'children');

for(i=1:length(foo))
  if(strcmp(get(foo(i),'style'),'popupmenu'))
    set(foo(i),'position',[10,tmp(4)-30,70,20]);
  elseif(strcmp(get(foo(i),'style'),'text'))
    set(foo(i),'position',[10,10,300,15]);
  else
    switch(get(foo(i),'string'))
      case('<')
        set(foo(i),'position',[80,tmp(4)-30,20,20]);
      case('^')
        set(foo(i),'position',[100,tmp(4)-30,20,20]);
      case('v')
        set(foo(i),'position',[120,tmp(4)-30,20,20]);
      case('>')
        set(foo(i),'position',[140,tmp(4)-30,20,20]);
      case('(f)req')
        set(foo(i),'position',[160,tmp(4)-30,40,20]);
      case('(t)ime')
        set(foo(i),'position',[200,tmp(4)-30,40,20]);
      case('(b)ispectrum')
        set(foo(i),'position',[240,tmp(4)-30,80,20]);
      case('(m)ulti-taper F-test')
        set(foo(i),'position',[320,tmp(4)-30,120,20]);
      case('(p)ulse')
        set(foo(i),'position',[440,tmp(4)-30,50,20]);
      case('(s)ine')
        set(foo(i),'position',[490,tmp(4)-30,50,20]);
      case('(d)elete')
        set(foo(i),'position',[540,tmp(4)-30,50,20]);
      case('(l)isten')
        set(foo(i),'position',[590,tmp(4)-30,50,20]);
      case('save')
        set(foo(i),'position',[640,tmp(4)-30,40,20]);
    end
  end
end


function windowkeypressFcn(src,evt)

global NW K NFFT FS

switch(evt.Key)
  case('leftarrow')
    if(strcmp(evt.Modifier,'shift'))
      yzoomout_callback;
    else
      panleft_callback;
    end
  case('uparrow')
    if(strcmp(evt.Modifier,'shift'))
      panup_callback;
    else
      xzoomin_callback;
    end
  case('downarrow')
    if(strcmp(evt.Modifier,'shift'))
      pandown_callback;
    else
      xzoomout_callback;
    end
  case('rightarrow')
    if(strcmp(evt.Modifier,'shift'))
      yzoomin_callback;
    else
      panright_callback;
    end
  case('f')
    nfftup_callback;
  case('t')
    nfftdown_callback;
  case('b')
    bispectrum_callback;
  case('m')
    ftest_callback;
  case('p')
    addpulse_callback;
  case('s')
    addsine_callback;
  case('d')
    delete_callback;
  case('l')
    listen_callback;
  case('n')
    if(strcmp(evt.Modifier,'shift'))
      if((NW+1)<(NFFT/2))
        NW=NW+1;
      end
    else
      NW=max(ceil((K+1)/2),NW-1);
    end
    update;
  case('k')
    if(strcmp(evt.Modifier,'shift'))
      K=min(2*NW-1,K+1);
    else
      K=K-1;
    end
    update;
end



function changechannel_callback(hObject,eventdata)

global FILE DATA RAW CHANNEL NARGIN

CHANNEL=get(hObject,'value');
if(NARGIN==1)
  RAW=daqread(FILE,'Channel',CHANNEL);
else
  RAW=DATA(:,CHANNEL);
end
update;



function panleft_callback(hObject,eventdata)

global XPAN XZOOM;

XPAN=max(0,XPAN-XZOOM/2);
update;



function panright_callback(hObject,eventdata)

global XPAN XZOOM RAW FS;

XPAN=min(length(RAW)/FS-XZOOM,XPAN+XZOOM/2);
update;



function panup_callback(hObject,eventdata)

global YPAN YZOOM RAW FS;

YPAN=min(FS/2-YZOOM,YPAN+YZOOM/2);
update;



function pandown_callback(hObject,eventdata)

global YPAN YZOOM RAW FS;

YPAN=max(0,YPAN-YZOOM/2);
update;



function xzoomin_callback(hObject,eventdata)

global XPAN XZOOM;

if(XZOOM<0.01)  return;  end;
XZOOM=XZOOM/2;
XPAN=XPAN+XZOOM/2;
update;



function yzoomin_callback(hObject,eventdata)

global YPAN YZOOM;

if(YZOOM<10)  return;  end;
YZOOM=YZOOM/2;
YPAN=YPAN+YZOOM/2;
update;



function xzoomout_callback(hObject,eventdata)

global XPAN XZOOM RAW FS;

XPAN=max(0,XPAN-XZOOM/2);
XZOOM=XZOOM*2;
if((XPAN+XZOOM)>(length(RAW)/FS))
  XZOOM=(length(RAW)/FS)-XPAN;
end
update;



function yzoomout_callback(hObject,eventdata)

global YPAN YZOOM RAW FS;

YPAN=max(0,YPAN-YZOOM/2);
YZOOM=YZOOM*2;
if((YPAN+YZOOM)>(FS/2))
  YZOOM=FS/2-YPAN;
end
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

global RAW XPAN XZOOM FS;

sound(RAW((1+ceil(XPAN*FS)):floor((XPAN+XZOOM)*FS)),FS);



function save_callback(hObject,eventdata)

global FILE PULSE SINE NARGIN VARARGOUT;

if(NARGIN==1)
  save([FILE '_byhand.mat'],'PULSE','SINE');
else
  save(['workspace_byhand.mat'],'PULSE','SINE');
end



function nfftup_callback(hObject,eventdata)

global NFFT NW K FTEST FS

NFFT=NFFT*2;
update;



function nfftdown_callback(hObject,eventdata)

global NFFT NW K FTEST FS

NFFT=NFFT/2;
if(FTEST)
  while(NW>=(NFFT/2))
    NW=NW-1;
  end
  if(K>(2*NW-1))
    K=floor(2*NW-1);
  end
end
update;



function bispectrum_callback(hObject,eventdata)

global BISPECTRUM

BISPECTRUM=~BISPECTRUM;
update;



function ftest_callback(hObject,eventdata)

global FTEST NW K NFFT FS

FTEST=~FTEST;
if(FTEST)
  while(NW>(NFFT/2))
    NW=NW-1;
  end
  if(K>(2*NW-1))
    K=floor(2*NW-1);
  end
end
update;



function update

global RAW IDXP IDXS XPAN XZOOM YPAN YZOOM UNITS
global CHANNEL FILE PULSE SINE PULSE_MODE NFFT
global FS BISPECTRUM FTEST PARAMS NW K TEXT

if(FTEST)
  set(TEXT,'string',['dT=' num2str(NFFT/FS) ' s, dF=' num2str(FS/NFFT) ' Hz, NW=' num2str(NW) ' (' num2str(round(NW/NFFT*FS)) ' Hz), K=' num2str(K)]);
else
  set(TEXT,'string',['dT=' num2str(NFFT/FS) ' s, dF=' num2str(FS/NFFT) ' Hz']);
end

foo2=(1+ceil(XPAN*FS)):floor((XPAN+XZOOM)*FS);
foo=RAW(foo2);

subplot(2,1,1);  cla;  hold on;
if(length(foo)>NFFT)
  if(FTEST)
    if(isempty(PARAMS)||(PARAMS.NW~=NW)||(PARAMS.K~=K)||(PARAMS.NFFT~=NFFT))
      PARAMS=[];
      PARAMS.NW=NW;
      PARAMS.K=K;
      PARAMS.NFFT=NFFT;
      [PARAMS.tapers,bar]=dpsschk([NW K],NFFT,FS);
      PARAMS.Fs=FS;
      PARAMS.pad=0;
      PARAMS.fpass=[0 FS/2];
    end
    kk=ceil((length(foo)-NFFT+1)/(NFFT/2));
    %tmp=max(256,2^nextpow2(NFFT))/2+1;
    tmp=2^nextpow2(NFFT)/2+1;
    p=zeros(tmp,kk);
    F=zeros(tmp,kk);
    f=zeros(tmp,kk);
    sig=zeros(kk);
    sd=zeros(tmp,kk);
    t=(0:(kk-1))*NFFT/2/FS+NFFT/2/FS;
    for k=1:kk
      i=1+(k-1)*NFFT/2;
      [F(:,k),p(:,k),f(:,k),sig(k),sd(:,k)] = ftestc(foo(i:(i+NFFT-1)),PARAMS,0.01/NFFT,'n');
    end
    f=f(:,1);  sig=sig(1);  sd=sd(:,1);
  else
    [s,f,t,p]=spectrogram(foo',NFFT,[],[],FS,'yaxis');
    if(BISPECTRUM)
      [p,f]=my_polyspectrum(s',f,[1 2 -3]);
      p=p';
      %need to whiten signal to shuffle confidence intervals onto bispectrum
      %p=abs(p');
      %dd=zeros(100,NFFT);
      %rand('twister',sum(100*clock));
      %for(i=1:size(dd,1))
      %  dd(i,:)=foo(ceil(length(foo).*rand(NFFT,1)));
      %end
      %[tA fA]=my_pwelch(dd,NFFT,FS);
      %[tB fB]=my_polyspectrum(tA,fA,[1 2 -3]);
      %nB=max(abs(tB),[],1);
      %idx=find(p<repmat(nB',1,size(p,2)));
      %p(idx)=0;
    end
  end
  fidx=find(f>=YPAN & f<=(YPAN+YZOOM));
  tmp=log10(abs(p(fidx,:)));
  tmp4=reshape(tmp,1,prod(size(tmp)));
  tmp2=prctile(tmp4,1);
  tmp3=prctile(tmp4,99);
  idx=find(tmp<tmp2);  tmp(idx)=tmp2;
  idx=find(tmp>tmp3);  tmp(idx)=tmp3;
  surf((t+foo2(1)./FS).*UNITS{1},f(fidx),tmp,'EdgeColor','none');
  if(BISPECTRUM)
    colormap(gray);
  else
    colormap(flipud(gray));
    if(FTEST)
      [i,j]=find(F>repmat(sig,size(F)));
      tmp=t(2)-t(1);  tmp2=f(2)-f(1);
      for(k=1:length(i))
        plot((t(j(k))+[0 tmp tmp 0 0]+foo2(1)/FS),...
            f(i(k))+[0 0 tmp2 tmp2 0],'g-');
      end
    end
  end
  axis tight;
  ylabel('frequency (Hz)');
end

subplot(2,1,2);  cla;  hold on;

IDXP=[];
if(~isempty(PULSE))
  if(PULSE_MODE==1)
    IDXP=find((PULSE(:,1)==CHANNEL) & ...
           (((PULSE(:,2)>=XPAN) & (PULSE(:,2)<=(XPAN+XZOOM)))));
  else
    IDXP=find((PULSE(:,1)==CHANNEL) & ...
           (((PULSE(:,2)>=XPAN) & (PULSE(:,2)<=(XPAN+XZOOM))) | ...
            ((PULSE(:,3)>=XPAN) & (PULSE(:,3)<=(XPAN+XZOOM)))));
  end
end

IDXS=[];
if(~isempty(SINE))
  IDXS=find((SINE(:,1)==CHANNEL) & ...
           (((SINE(:,2)>=XPAN) & (SINE(:,2)<=(XPAN+XZOOM))) | ...
            ((SINE(:,3)>=XPAN) & (SINE(:,3)<=(XPAN+XZOOM)))));
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
plot(foo2./FS.*UNITS{1},foo,'k');

axis tight;
v=axis;
axis([foo2(1)./FS.*UNITS{1} foo2(end)./FS.*UNITS{1} v(3) v(4)]);
xlabel(['time (' UNITS{2} ')']);

v=axis;
subplot(2,1,1);
vv=axis;
axis([v(1) v(2) YPAN YPAN+YZOOM]);
