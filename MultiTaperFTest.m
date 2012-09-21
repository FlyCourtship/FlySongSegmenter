%function SSF=MultiTaperFTest(d,fs,NW,K,dT,dS,pval)
%
%d=decimate(d,4); fs=fs/4; % if fs>10e3
%ssf=MultiTaperFTest(d,fs,11,21,0.02,0.01,0.01) % mosquito
%ssf=MultiTaperFTest(d,fs,12,20,0.1,0.01,0.05) % fruit fly
%SINEsongfinder_plot(ssf);
%
%NW = time-bandwidth product for tapers
%K = num independent tapers to average over, must be < 2*NW
%dT = window length
%dS = window step size
%pval = criterion for F-test
%
%optional:
%fwindow = [0 fs/2]; %search from 0Hz to Nyquist freq
%fwindow = [0 1000]; %search from 0 to 1000Hz
%reduced_memory = 1, don't save SSF.Fval - used by FlySongSegmenter
%reduced_memory = 0, save SSF.Fval
%
%might need to:
%addpath chronux\spectral_analysis\helper\
%addpath chronux\spectral_analysis\continuous\

function SSF=MultiTaperFTest(d,fs,NW,K,dT,dS,pval,fwindow)
% pool = exist('matlabpool','file');
if nargin < 8
    fwindow = [0 fs/2];
end

dT2=round(dT*fs);
dS2=round(dS*fs);
d=d-repmat(mean(d),size(d,1),1);

[tapers,eigs]=dpsschk([NW K],dT2,fs);

params=[];
params.tapers=tapers;
params.Fs=fs;
params.pad=0;
params.fpass=fwindow;


kk=ceil((length(d)-dT2+1)/dS2);

pos = 1:dS2:dS2*kk;
[f,findx]=getfgrid(params.Fs,max(2^(nextpow2(dT2)+params.pad),dT2),params.fpass);
dim1 = length(f);
Fval=zeros(dim1,1, 'single');A=zeros(dim1,kk, 'single');
[~,~,f,sig,~] = ftestc(d(1:(1+dT2-1)),params,pval/dT2,'n');
events_cell = cell(size(A,2),1);
t=(0:(size(A,2)-1))*dS2/fs;
parfor k=1:kk
    [Fval,A(:,k),~,~,~] = ftestc(d(pos(k):(pos(k)+dT2-1)),params,pval/dT2,'n');
    fmax=crx_findpeaks(Fval,sig); %this function name is a hack. chronux 'findpeaks' conflicts with Matlab 'findpeaks'.
    %I have renamed the chronux function as crx_findpeaks and changed this line too.
    %This means this code is incompatible with the public version of chronux.
    %Users must use our version. Future versions of chronux are expected to
    %fix this namespace conflict, which will require rewrite of this line.
    events_cell{k}=[repmat(t(k)+dT/2,length(fmax(1).loc),1) f(fmax(1).loc)'];
end
t = t +dT/2;

events = cell2mat(events_cell);
events(:,1) = round(events(:,1)*fs);


SSF.d=d;
SSF.fs=fs;
SSF.NW=NW;
SSF.K=K;
SSF.dT=dT;
SSF.dS=dS;
SSF.pval=pval;
SSF.t=round(t.*fs);%return time in sample units
SSF.f=f;
SSF.A=A;
SSF.events=events;
