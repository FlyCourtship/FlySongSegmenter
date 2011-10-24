%function SSF=sinesongfinder(d,fs,NW,K,dT,dS,pval)
%
%d=decimate(d,4);  fs=fs/4;  % if fs>10e3
%ssf=sinesongfinder(d,fs,11,21,0.02,0.01,0.01)  % mosquito
%ssf=sinesongfinder(d,fs,12,20,0.1,0.01,0.05)  % fruit fly
%SINEsongfinder_plot(ssf);
%
%NW = time-bandwidth product for tapers
%K = num independent tapers to average over, must be < 2*NW
%dT = window length
%dS = window step size
%pval = criterion for F-test
%
%might need to:
%addpath chronux\spectral_analysis\helper\
%addpath chronux\spectral_analysis\continuous\

function SSF=sinesongfinder(d,fs,NW,K,dT,dS,pval)

dT2=round(dT*fs);
dS2=round(dS*fs);
plotit=0;  % plot it, or don't plot it, there is no try

% [d t]=daqread(filename);  % do it this way when pipelined
% d=d(:,chan);
d=d-repmat(mean(d),size(d,1),1);
% fs=1/max(diff(t));

[tapers,eigs]=dpsschk([NW K],dT2,fs);

params=[];
params.tapers=tapers;
params.Fs=fs;
params.pad=0;
params.fpass=[0 fs/2];
i=1;
kk=ceil((length(d)-dT2+1)/dS2);
[f,findx]=getfgrid(params.Fs,max(2^(nextpow2(dT2)+params.pad),dT2),params.fpass);
Fval=zeros(length(f),kk);  A=zeros(length(f),kk);
for(k=1:kk)
  [Fval(:,k),A(:,k),f,sig,sd] = ftestc(d(i:(i+dT2-1)),params,pval/dT2,'n');
  i=i+dS2;
end
t=(0:(size(Fval,2)-1))*dS2/fs;
events=[];
for(i=1:size(Fval,2))
  fmax=crx_findpeaks(Fval(:,i),sig); %this function name is a hack. chronux 'findpeaks' conflicts with Matlab 'findpeaks'.
  %I have renamed the chronux function as crx_findpeaks and changed this line too.
  %This means this code is incompatible with the public version of chronux.
  %Users must use our version. Future versions of chronux are expected to
  %fix this namespace conflict, which will require rewrite of this line.
  events=[events; ...
        repmat(t(i)+dT/2,length(fmax(1).loc),1) f(fmax(1).loc)'];
   if(plotit & length(fmax(1).loc)>0)  % show the individual time slices separately
     clf;
     subplot(3,1,1);
     plot(f,abs(A(:,i)),'k');
     ylabel('amplitude');
     title(['# tapers = ' num2str(K) ', win len = ' num2str(dT) ', win step = ' num2str(dS)]);
     subplot(3,1,2);  hold on;
     plot(f,Fval(:,i),'k');
     plot([min(f) max(f)],[sig sig],'k:');
     for(j=1:length(fmax(1).loc))
       plot(f(fmax(1).loc(j)),interp1(f,Fval(:,i),f(fmax(1).loc(j))),'ko');
     end
     %axis([0 1000 0 1]);
     ylabel('F-stat');
     subplot(3,1,3);
     idx=round(t(i)*fs):round((t(i)+dT)*fs);
     plot(idx,d(idx),'k');
     axis tight
     xlabel('frequency (Hz)');
     ylabel('time series');
     keyboard;  % 'return' to continue
   end
end

SSF.d=d;
SSF.fs=fs;
SSF.NW=NW;
SSF.K=K;
SSF.dT=dT;
SSF.dS=dS;
SSF.pval=pval;
SSF.t=t;
SSF.f=f;
SSF.A=A;
SSF.Fval=Fval;
SSF.events=events;
