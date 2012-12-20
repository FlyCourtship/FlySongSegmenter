%function PlotMultiTaperFTest(sines,params,data,freq_range)
%
%utility to plot the output of MultiTaperFTest.  usage:
%PlotMultiTaperFTest(Sines.MultiTaper,Params,Data,[50 250]);

function PlotMultiTaperFTest(sines,params,data,freq_range)

handles.sines=sines;
handles.params=params;
handles.data=data;
handles.freq_range=freq_range;

handles.figure1=figure;
foo=get(handles.figure1,'Position');
set(handles.figure1,'Position',round([400 250 1.5*foo(3) 1.5*foo(4)]));
tmp=get(gcf,'position');  tmp2=get(gcf,'color');

uicontrol(handles.figure1,'style','pushbutton','string','zoom in', ...
   'callback', @zoom_in_callback, ...
   'position',[0 0 70 20]);
uicontrol(handles.figure1,'style','pushbutton','string','zoom out', ...
   'callback', @zoom_out_callback, ...
   'position',[75 0 70 20]);
uicontrol(handles.figure1,'style','pushbutton','string','pan left', ...
   'callback', @pan_left_callback, ...
   'position',[150 0 70 20]);
uicontrol(handles.figure1,'style','pushbutton','string','pan right', ...
   'callback', @pan_right_callback, ...
   'position',[225 0 70 20]);

handles.left=0;
handles.right=(length(handles.data.d)-1)/handles.data.fs;

plot_it(handles);

guidata(handles.figure1,handles);


function plot_it(handles)

ax1=subplot(5,1,1);
idx=1+(round(handles.left*handles.data.fs):round(handles.right*handles.data.fs));
plot(idx./handles.data.fs,handles.data.d(idx),'k-');
title(['NW=' num2str(handles.params.NW) ', K=' num2str(handles.params.K) ', dT=' num2str(handles.params.dT) ', dS=' num2str(handles.params.dS) ', pval=' num2str(handles.params.pval)]);
axis tight

ax2=subplot(5,1,[2 3]);
tmpT=handles.sines.t/handles.data.fs+handles.params.dT/2-handles.params.dS/2;
idxT=find(((tmpT+handles.params.dS)>=handles.left) & ((tmpT-handles.params.dS)<=handles.right));
idxF=find((handles.sines.f>=handles.freq_range(1)) & (handles.sines.f<=handles.freq_range(2)));
surf(tmpT(idxT),handles.sines.f(idxF),double(abs(handles.sines.A(idxF,idxT))),'EdgeColor','none');
%surf(tmpT(idxT),handles.f-min(diff(handles.f))/2,log10(handles.Fval(:,idxT)),'EdgeColor','none');
axis xy;  axis tight;  view(0,90);
axis([handles.left handles.right handles.freq_range]);
colormap(flipud(gray));
ylabel('frequency (Hz)');

ax3=subplot(5,1,[4 5]);
idx=find((handles.sines.events(:,1)>=handles.left*handles.data.fs) & (handles.sines.events(:,1)<=handles.right*handles.data.fs));
plot(handles.sines.events(idx,1)./handles.data.fs,handles.sines.events(idx,2),'k.','markersize',24);
axis([handles.left handles.right handles.freq_range]);
grid on;
xlabel('time (s)');
ylabel('frequency (Hz)');
linkaxes([ax1 ax2 ax3],'x');


function zoom_in_callback(obj,evt)

handles=guidata(obj);
tmp1=(handles.left+handles.right)/2;
tmp2=handles.right-handles.left;
handles.left=max(0,tmp1-tmp2/4);
handles.right=min((length(handles.data.d)-1)/handles.data.fs,tmp1+tmp2/4);
plot_it(handles);
guidata(handles.figure1,handles);


function zoom_out_callback(obj,evt)

handles=guidata(obj);
tmp1=(handles.left+handles.right)/2;
tmp2=handles.right-handles.left;
handles.left=max(0,tmp1-tmp2);
handles.right=min((length(handles.data.d)-1)/handles.data.fs,tmp1+tmp2);
plot_it(handles);
guidata(handles.figure1,handles);


function pan_left_callback(obj,evt)

handles=guidata(obj);
tmp2=min(handles.left,(handles.right-handles.left)/2);
handles.left=handles.left-tmp2;
handles.right=handles.right-tmp2;
plot_it(handles);
guidata(handles.figure1,handles);


function pan_right_callback(obj,evt)

handles=guidata(obj);
tmp2=min((length(handles.data.d)-1)/handles.data.fs-handles.right,(handles.right-handles.left)/2);
handles.left=handles.left+tmp2;
handles.right=handles.right+tmp2;
plot_it(handles);
guidata(handles.figure1,handles);
