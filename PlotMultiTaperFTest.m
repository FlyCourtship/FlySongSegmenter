%function PlotMultiTaperFTest(ssf,freq_range)
%
%utility to plot the output of MultiTaperFTest.  usage:
%PlotMultiTaperFTest(Sine.MultiTaper,[50 250]);

function PlotMultiTaperFTest(ssf,freq_range)

global SSF

SSF=ssf;
%SSF.t = SSF.t ./ SSF.fs;

if(~isfield(SSF,'h'))
  SSF.h=figure;
  foo=get(SSF.h,'Position');
  set(SSF.h,'Position',round([400 250 1.5*foo(3) 1.5*foo(4)]));
  tmp=get(gcf,'position');  tmp2=get(gcf,'color');

  zoom_in_button=uicontrol('style','pushbutton','string','zoom in', ...
     'callback', ['global SSF;  tmp1=(SSF.left+SSF.right)/2;  tmp2=SSF.right-SSF.left;  SSF.left=max(0,tmp1-tmp2/4);  SSF.right=min((length(SSF.d)-1)/SSF.fs,tmp1+tmp2/4);  PlotMultiTaperFTest(SSF,[' num2str(freq_range) ']);'], ...
     'position',[0 0 70 20]);
  zoom_out_button=uicontrol('style','pushbutton','string','zoom out', ...
     'callback', ['global SSF;  tmp1=(SSF.left+SSF.right)/2;  tmp2=SSF.right-SSF.left;  SSF.left=max(0,tmp1-tmp2);  SSF.right=min((length(SSF.d)-1)/SSF.fs,tmp1+tmp2);  PlotMultiTaperFTest(SSF,[' num2str(freq_range) ']);'], ...
     'position',[75 0 70 20]);
  pan_left_button=uicontrol('style','pushbutton','string','pan left', ...
     'callback', ['global SSF;  tmp2=min(SSF.left,(SSF.right-SSF.left)/2);  SSF.left=SSF.left-tmp2;  SSF.right=SSF.right-tmp2;  PlotMultiTaperFTest(SSF,[' num2str(freq_range) ']);'], ...
     'position',[150 0 70 20]);
  pan_right_button=uicontrol('style','pushbutton','string','pan right', ...
     'callback', ['global SSF;  tmp2=min((length(SSF.d)-1)/SSF.fs-SSF.right,(SSF.right-SSF.left)/2);  SSF.left=SSF.left+tmp2;  SSF.right=SSF.right+tmp2;  PlotMultiTaperFTest(SSF,[' num2str(freq_range) ']);'], ...
     'position',[225 0 70 20]);

  SSF.left=0;
  SSF.right=(length(SSF.d)-1)/SSF.fs;
else
  figure(SSF.h);
end

%[SSF.left SSF.right]

ax1=subplot(5,1,1);
idx=1+(round(SSF.left*SSF.fs):round(SSF.right*SSF.fs));
plot(idx./SSF.fs,SSF.d(idx),'k-');
title(['NW=' num2str(SSF.NW) ', K=' num2str(SSF.K) ', dT=' num2str(SSF.dT) ', dS=' num2str(SSF.dS) ', pval=' num2str(SSF.pval)]);
axis tight

ax2=subplot(5,1,[2 3]);
tmpT=SSF.t/SSF.fs+SSF.dT/2-SSF.dS/2;
idxT=find(((tmpT+SSF.dS)>=SSF.left) & ((tmpT-SSF.dS)<=SSF.right));
idxF=find((SSF.f>=freq_range(1)) & (SSF.f<=freq_range(2)));
surf(tmpT(idxT),SSF.f(idxF),double(abs(SSF.A(idxF,idxT))),'EdgeColor','none');
%surf(tmpT(idxT),SSF.f-min(diff(SSF.f))/2,log10(SSF.Fval(:,idxT)),'EdgeColor','none');
axis xy;  axis tight;  view(0,90);
axis([SSF.left SSF.right freq_range]);
colormap(flipud(gray));
ylabel('frequency (Hz)');

ax3=subplot(5,1,[4 5]);
idx=find((SSF.events(:,1)>=SSF.left*SSF.fs) & (SSF.events(:,1)<=SSF.right*SSF.fs));
plot(SSF.events(idx,1)./SSF.fs,SSF.events(idx,2),'k.','markersize',24);
axis([SSF.left SSF.right freq_range]);
grid on;
xlabel('time (s)');
ylabel('frequency (Hz)');
linkaxes([ax1 ax2 ax3],'x');
