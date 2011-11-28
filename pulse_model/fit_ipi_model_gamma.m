function [ipi,LR_ipi] = fit_ipi_model_gamma(pulsetimes,fs)
%provide pulses
%return info about ipis, including gamma parameters

%p are pulses (=pulseInfo2.wc)
fprintf('fitting ipi model\n')
p = pulsetimes ./ fs;

%e.g. pulsetimes = pulseInfo.wc

%grab all ipis

p_shift_one = circshift(p,[0 -1]);
ipi_d=p_shift_one(1:end-1)-p(1:end-1);


%Part 1

%Estimate gamma dist parameters from gamma mixture model

gamparamEsts = gamma_fit(ipi_d);%returns p,A1,A2,B1,B2

%get parameters from better fit p or p-1

prop = gamparamEsts.p;
if prop >= 0.5
    choose = 1;
else
    choose = 2;
end

alpha = gamparamEsts.A(choose);
beta = gamparamEsts.B(choose);

%calculate mean and variance from gamma parameters
[gamu,gamV] = gamstat(alpha,beta);
gamS = sqrt(gamV);


% %Part 2
% 
% %calculate likelihood ratio that is real ipi vs neihhboring ipis
% %number of neighboring pulses to compare
% 
% comp=10;
% 
% %pad with comp 0's, shift for all comparisons
% 
% p_pad_all = [zeros(comp,1);p';zeros(comp,1)]';
% x=0;
% for n=-comp:1:comp;
%     x=x+1;
%     Z(x,:)=circshift(p_pad_all,[1 n]);
%     D(x,:)=p_pad_all-Z(x,:);
% end
% 
% %remove leading and trailing columns and last column which is a
% %non-sensical ipi of last minus first
% D = D(:,comp+1:end-comp-1);
% %remove middle row (all 0's) to avoid weird fits
% D = D([1:comp end-comp+1:end],:);
% D = abs(D);
% 
% %calc pdf for each shifted ipi relative to model
% 
% %calc pdf for these parameters
% D_pdf = gampdf(D,alpha,beta);
% %get highest density for each time
% max_D_pdf = max(D_pdf);
% 
% mean_waiting_time = gamu;
% l=1/mean_waiting_time;
% D_pois = l*exp(-l.*D);
% 
% %D_pois = poisspdf(D,ipi_mean);
% max_D_pois = max(D_pois);
% %calc pdf for each shifted ipi relative to Poisson
% LR_D = max_D_pdf./max_D_pois;
% 
% 
% LR_ipi = LR_D;
ipi = struct('d',ipi_d,'alpha',alpha,'beta',beta,'gamu',gamu,'gamS',gamS,'fit',gamparamEsts);%results in units of samples
