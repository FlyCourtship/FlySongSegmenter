function [ipiStats lombStats culled_ipi] = cullIPILomb(ipi)

%
%collect relevant ipi data, return u, S for each, calc Lomb periodgram sign
%peaks at certain alpha (use 0.01 to start)
%

alphaThresh = 0.05;

%get two dominant mixture components

a = ipi.fit.PComponents;
b = sort(a,'descend');
MP1 = b(1);%mixing proportions
MP2 = b(2);
C1 = find(a == MP1);%components
C2 = find(a == MP2);

culled_ipi = cullByCdf(ipi,[C1 C2],.01);

%re-estimate mixing proportions
options = statset('MaxIter',500);
obj=gmdistribution.fit(culled_ipi.d',2,'options',options);

a = obj.mu;
b = sort(a,'ascend');
MP1 = b(1);
MP2 = b(2);

%reduce to one fit if one fit explains most of the data
if MP1 > 0.9%if the top fit explains most of the data, then take just these data
    culled_ipi = cullByCdf(ipi,C1,.01);
    obj=gmdistribution.fit(culled_ipi.d',1,'options',options);
    mu = obj.mu;
    sig = obj.Sigma;
    mu1 = mu;
    mu2 = NaN;
    sig1 = sig;
    sig2 = NaN;
else
    mu = obj.mu;
    sig = obj.Sigma;
    C1 = find(a == MP1);
    C2 = find(a == MP2);
    mu1 = mu(C1);
    mu2 = mu(C2);
    sig1 = sig(C1);
    sig2 = sig(C2);
end


%calculate lomb-scargle periodgram
[P,f,alpha]=lomb(culled_ipi.d,culled_ipi.t);
%get peaks
peaks = regionalmax(P);
%get f,alpha,Peaks for peaks < desired alpha
fPeaks = f(peaks);
alphaPeaks = alpha(peaks);

signF = fPeaks(alphaPeaks < alphaThresh);
signAlpha = alphaPeaks(alphaPeaks <alphaThresh);
signPeaks = P(alphaPeaks < alphaThresh);

ipiStats.mu1 = mu1;
ipiStats.mu2 = mu2;
ipiStats.S1 = sig1;
ipiStats.S2 = sig2;
lombStats.F = signF;
lombStats.Alpha = signAlpha;
lombStats.Peaks = signPeaks;
