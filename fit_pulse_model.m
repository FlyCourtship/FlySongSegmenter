function [pulse_model,Lik_pulse] = fit_pulse_model(pulses)
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

%fit_pulse_model differs from fit_pulseharm_model in the following way
%fit_pulseharm_model reestimates the models (and SD) using data that
%appears to fit each harmonic best
%fit_pulse_model estimates only the fundamental frequency model using data
%that best fits this model. It then decimates the model and best fit data
%to build the second and third harmonic models for likelihood testing

%d will often = pulseInfo2.x


fprintf('Fitting pulse model\n')
d = pulses;

%grab samples, center, and pad

n_samples = length(d);
max_length = max(cellfun(@length,d));
total_length = 2* max_length;
Z = zeros(n_samples,total_length );
for n=1:n_samples;
    X = d{n};
    T = length(X);
    [~,C] = max(X);%get position of max power
        
    %center on max power
    left_pad = max_length - C;  %i.e. ((total_length/2) - C)
    right_pad = total_length - T - left_pad;
    Z(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
end

[M,Z] = alignpulses(Z,20);
[~,Z] = realign_abberant_peaks(M,Z);


%Generate second harmonic model
fprintf('Fitting second harmonic model\n')

shM = decimate(M,2);
delta = abs(length(shM) - length(M));
left_pad = round(delta/2);
right_pad = delta -left_pad;
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];

[shZ,~] = alignpulses2model(Z,shM);


%Generate third harmonic model

fprintf('Fitting third harmonic model\n')

thM = decimate(M,3);
delta = abs(length(thM) - length(M));
left_pad = round(delta/2);
right_pad = delta -left_pad;
thM = [zeros(left_pad,1)',thM,zeros((right_pad),1)'];

[thZ,~] = alignpulses2model(Z,thM);


%Generate phase reversed model
fprintf('Fitting phase reversed model\n')

RM = -M;

[RZ,~] = alignpulses2model(Z,RM);
[~,RZ] = realign_abberant_peaks(RM,RZ);


%Generate phase reversed second harmonic model
fprintf('Fitting phase reversed second harmonic model\n')

shRM = -shM;

[shRZ,~] = alignpulses2model(Z,shRM);
[~,shRZ] = realign_abberant_peaks(shRM,shRZ);

%Generate phase reversed third harmonic model
fprintf('Fitting phase reversed third harmonic model\n')

thRM = -thM;

[thRZ,~] = alignpulses2model(Z,thRM);
[~,thRZ] = realign_abberant_peaks(thRM,thRZ);


for n=1:n_samples;
%calc chi-square for first model
    chisq(n,1) = ...
        mean((Z(n,:) - M).^2./var(Z(n,:)));
%calc chi-square for second harmonic model
    chisq(n,2) = ...
        mean((shZ(n,:) - shM).^2./var(shZ(n,:)));
%calc chi-square for third harmonic model
    chisq(n,3) = ...
        mean((thZ(n,:) - thM).^2./var(thZ(n,:)));    
%calc chi-square for reversed model
    chisq(n,4) = ...
        mean((RZ(n,:) - RM).^2./var(RZ(n,:)));
%calc chi-square for reversed second harmonic model
    chisq(n,5) = ...
        mean((shRZ(n,:) - shRM).^2./var(shRZ(n,:)));
%calc chi-square for reversed third harmonic model
    chisq(n,6) = ...
        mean((thRZ(n,:) - thRM).^2./var(thRZ(n,:)));    

end

[~,best_chisqr_idx] = min(chisq,[],2);

%flip data that fits a reversed model better (columns 3 or 4)
for n=1:n_samples
    if best_chisqr_idx(n) > 3
        Z(n,:) = -Z(n,:);
    end
end

%use rem(number,2) to determine if even (false =0) or odd (true = 1)

%grab events that fit first harmonic model better
fhZ = Z(best_chisqr_idx == 1 | best_chisqr_idx == 4,:);
%grab events that fit second harmonic model better
%shZ = Z(best_chisqr_idx == 2 | best_chisqr_idx == 5,:);
%grab events that fit second harmonic model better
%thZ = Z(best_chisqr_idx == 3 | best_chisqr_idx == 6,:);


%compare models with Lik analysis
%first make two de novo models from presumptive first and second harmonic
%data
%then, compare all data to each model with likelihood analysis

%de novo fit low freq model
%take mean of columns

%Build model of fh with fh data
fprintf('Building first harmonic model.\n');
[fhM,fhZ] = alignpulses(fhZ,20);
[~,fhZ] = realign_abberant_peaks(fhM,fhZ);

%Decimate fhZ data to fit shM and thM

shZ = downsample(fhZ',2);
shZ = shZ';
thZ = downsample(fhZ',3);
thZ = thZ';

%pad shZ and thZ to same size as Z
delta = abs(size(shZ,2) - size(Z,2));
left_pad = round(delta/2);
right_pad = delta - left_pad;
m = size(shZ,1);
left_pad_ar = zeros(m,left_pad);
right_pad_ar = zeros(m,right_pad);
shZ = [left_pad_ar,shZ,right_pad_ar];

delta = abs(size(thZ,2) - size(Z,2));
left_pad = round(delta/2);
right_pad = delta - left_pad;
m = size(shZ,1);
left_pad_ar = zeros(m,left_pad);
right_pad_ar = zeros(m,right_pad);
thZ = [left_pad_ar,thZ,right_pad_ar];


%Build model of sh with sh data
%de novo fit high freq model
%take mean of columns
% fprintf('Building second harmonic model.\n');
% [shM,shZ] = alignpulses(shZ,20);
% [~,shZ] = realign_abberant_peaks(shM,shZ);

%Build model of sh with sh data
%de novo fit high freq model
%take mean of columns
% fprintf('Building third harmonic model.\n');
% [thM,thZ] = alignpulses(thZ,20);
% [~,thZ] = realign_abberant_peaks(thM,thZ);


%Now realign all data to the two models
fprintf('Aligning all data to the models.\n');
[Z2fhM,~] = alignpulses2model(Z,fhM);
[~,Z2fhM] = realign_abberant_peaks(fhM,Z2fhM);

[Z2shM,~] = alignpulses2model(Z,shM);
[~,Z2shM] = realign_abberant_peaks(shM,Z2shM);

[Z2thM,~] = alignpulses2model(Z,thM);
[~,Z2thM] = realign_abberant_peaks(thM,Z2thM);


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

fhM = fhM(start:finish);
shM = shM(start:finish);
thM = thM(start:finish);
Z2fhM = Z2fhM(:,start:finish);
Z2shM = Z2shM(:,start:finish);
Z2thM = Z2thM(:,start:finish);
S_Z2fhM = std(Z2fhM);
S_Z2shM = std(Z2shM);
S_Z2thM = std(Z2thM);

%M_ar = repmat(M,size(Z,1),1);
%S_ar = repmat(S,size(Z,1),1);
S_ar_fh = repmat(S_Z2fhM,size(Z,1),1);
S_ar_sh = repmat(S_Z2shM,size(Z,1),1);
S_ar_th = repmat(S_Z2thM,size(Z,1),1);
%d_pdf = sum(log10(normpdf(Z,M_ar,S_ar)),2);
%u_pdf = sum(log10(normpdf(Z,0,S_ar)),2);



%%%%
%%calculate likelihood of data under each model

fhM_ar = repmat(fhM,size(Z2fhM,1),1);
LL_fhM = sum(log10(normpdf(Z2fhM,fhM_ar,S_ar_fh)),2);
LL_0_fhpdf = sum(log10(normpdf(Z2fhM,0,S_ar_fh)),2);

shM_ar = repmat(shM,size(Z2shM,1),1);
LL_shM = sum(log10(normpdf(Z2shM,shM_ar,S_ar_sh)),2);
LL_0_shpdf = sum(log10(normpdf(Z,0,S_ar_sh)),2);

thM_ar = repmat(thM,size(Z2thM,1),1);
LL_thM = sum(log10(normpdf(Z2thM,thM_ar,S_ar_th)),2);
LL_0_thpdf = sum(log10(normpdf(Z,0,S_ar_th)),2);

%LL_0_pdf = sum(log10(normpdf(Z,0,S_ar)),2);

LLR_fh = LL_fhM - LL_0_fhpdf;
LLR_sh = LL_shM - LL_0_shpdf;
LLR_th = LL_thM - LL_0_thpdf;

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
best_LLR = max(LLR_fh,LLR_sh);

%LR_best = d_best_pdf - u_pdf;
%LOD_for = d_pdf - u_pdf;
%LOD_rev = d_rev_pdf - u_pdf;

pulse_model.M = fhM;
pulse_model.fhZ = fhZ;%aligned pulses that fit first harmonic best
pulse_model.Z = Z2fhM;%aligned all pulses to first harmonic model
pulse_model.S = S_Z2fhM;
%pulse_model.fhM = fhM;
%pulse_model.shM = shM;
%pulse_model.shZ = Z2shM;

Lik_pulse.LLR_best = best_LLR;
Lik_pulse.LLR_fh = LLR_fh;
Lik_pulse.LLR_sh = LLR_sh;
Lik_pulse.LLR_th = LLR_th;
%Lik_pulse.d_pdf = d_pdf;
%Lik_pulse.u_pdf = u_pdf;
%Lik_pulse.d_rev_pdf = d_rev_pdf;


