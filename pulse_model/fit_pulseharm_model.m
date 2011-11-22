function [pulse_model,Lik_pulse] = fit_pulseharm_model(pulses)
%[pulse_model,Lik_pulse] = fit_pulseharm_model(pulses)
%USAGE
%calculate model and likelihoods
%[pulse_model,Lik_pulse] = fit_pulse_model(pulseInfo2.x)
%calculate just likelihoods from previously calculated model and aligned
%data
%[~,Lik_pulse] = fit_pulse_model([],pulse_model.M,pulse_model.Z)
%
%
%provide sample of pulses
%return pulse model & std etc and Lik of individual pulses given the model

%d will often = pulseInfo2.x


fprintf('Fitting pulse model\n')
d = pulses;

%grab samples, center, flip inverted phase, and pad

n_samples = length(d);
max_length = max(cellfun(@length,d));
total_length = 2* max_length;
Z = zeros(n_samples,total_length );
for n=1:n_samples;
    X = d{n};
    T = length(X);
    [~,C] = max(abs(X));%get position of max power
    %flip if phase inverted
    if X(C) < 0
        X = -X;
    end
    %center on max power
    left_pad = max_length - C;  %i.e. ((total_length/2) - C)
    right_pad = total_length - T - left_pad;
    Z(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
end

[M,Z] = alignpulses(Z,20);
[M,Z] = realign_abberant_peaks(M,Z);


%Generate second harmonic model
fprintf('Fitting second harmonic model\n')

hM = decimate(M,2);
[~,C] = max(hM);%get max power, then center on this
T = length(hM);
left_pad = T - C;  %i.e. ((total_length/2) - C)
right_pad = total_length - T - left_pad;
hM = [zeros(left_pad,1)',hM,zeros((right_pad),1)'];
hZ = Z;

%align each event to hM
for n = 1:n_samples;
    C = xcorr(hM,Z(n,:),'unbiased');
    [~,tpeak] = max(C);
    tpeak = tpeak - total_length;
    hZ(n,:) = circshift(hZ(n,:),[1 tpeak]);
    %a = mean(hM.*hZ(n,:))/mean(hZ(n,:).^2);
    %hZ(n,:) = a*hZ(n,:);
end

scale = sqrt(mean(hM.^2));
hM = hM/scale;
hZ = hZ/scale;


%calc chi-square for first model
for n=1:n_samples;
    chisqM(n) = ...
        mean((Z(n,:) - M).^2./var(Z(n,:)));
end

%calc chi-square for second harmonic model
for n=1:n_samples;
    chisqhM(n) = ...
        mean((hZ(n,:) - hM).^2./var(hZ(n,:)));
end


%grab events that fit first harmonic better
lfZ = Z(chisqhM>chisqM,:);
%grab events that fit first harmonic better
hfZ = Z(chisqhM<chisqM,:);

%compare models with Lik analysis
%first make two de novo models from presumptive first and second harmonic
%data
%then, compare all data to each model with likelihood analysis

%de novo fit low freq model
%take mean of columns

fprintf('Aligning pulses for first harmonic.\n');
[lfM,lfZ] = alignpulses(lfZ,20);
[lfM,lfZ] = realign_abberant_peaks(lfM,lfZ);


%de novo fit high freq model
%take mean of columns
fprintf('Aligning pulses for second harmonic.\n');
[hfM,hfZ] = alignpulses(hfZ,20);
[hfM,hfZ] = realign_abberant_peaks(hfM,hfZ);


%Calc SE of samples at point of peak signal and
%find first and last points that exceed abs of this SE
maxM = max(M);
samplepos = M==maxM;
st = std(Z(:,samplepos))/sqrt(n_samples);
start=find(abs(M)>st,1,'first');
finish=find(abs(M)>st,1,'last');

M = M(start:finish);
Z = Z(:,start:finish);
S = std(Z);

lfM = lfM(start:finish);
hfM = hfM(start:finish);
lfZ = lfZ(:,start:finish);
hfZ = hfZ(:,start:finish);

%M_ar = repmat(M,size(Z,1),1);
S_ar = repmat(S,size(Z,1),1);
%d_pdf = sum(log10(normpdf(Z,M_ar,S_ar)),2);
%u_pdf = sum(log10(normpdf(Z,0,S_ar)),2);



%%%%
%%calculate likelihood of data under each model

lfM_ar = repmat(lfM,size(Z,1),1);
LL_lfM = sum(log10(normpdf(Z,lfM_ar,S_ar)),2);

hfM_ar = repmat(hfM,size(Z,1),1);
LL_hfM = sum(log10(normpdf(Z,hfM_ar,S_ar)),2);

LL_0_pdf = sum(log10(normpdf(Z,0,S_ar)),2);

LLR_lf = LL_lfM - LL_0_pdf;
LLR_hf = LL_hfM - LL_0_pdf;

%do same for M_rev
%start=find(abs(M_rev)>st,1,'first');
%finish=find(abs(M_rev)>st,1,'last');

% M_rev = M_rev(start:finish);
% Z_rev = Z_rev(:,start:finish);
% S_rev = std(Z_rev);
% 
% 
% 
% 
% M_rev_ar = repmat(M_rev,size(Z,1),1);
% S_rev_ar = repmat(S_rev,size(Z,1),1);
% d_rev_pdf = sum(log10(normpdf(Z,M_rev_ar,S_rev_ar)),2);

%Get the Lik of the better model
%d_best_pdf = max(d_pdf,d_rev_pdf);

%compare fit to basic model and second harmonic model
best_LLR = max(LLR_lf,LLR_hf);

%LR_best = d_best_pdf - u_pdf;
%LOD_for = d_pdf - u_pdf;
%LOD_rev = d_rev_pdf - u_pdf;

pulse_model.M = M;
pulse_model.Z = Z;
pulse_model.S = S;
pulse_model.lfM = lfM;
pulse_model.hfM = hfM;
pulse_model.lfZ = lfZ;
pulse_model.hfZ = hfZ;

Lik_pulse.LLR_best = best_LLR;
Lik_pulse.LLR_lf = LLR_lf;
Lik_pulse.LLR_hf = LLR_hf;
%Lik_pulse.d_pdf = d_pdf;
%Lik_pulse.u_pdf = u_pdf;
%Lik_pulse.d_rev_pdf = d_rev_pdf;


