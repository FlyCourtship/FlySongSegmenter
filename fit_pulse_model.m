function [pulse_model,Lik_pulse] = fit_pulse_model(pulses)

%[pulse_model,Lik_pulse] = fit_pulse_model(pulses)
%USAGE
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

[fhZ,fhM] = alignpulses(Z,20);
[fhZ,~] = realign_abberant_peaks(fhZ,fhM);


%Generate second harmonic model
fprintf('Fitting second harmonic model\n')

shM = decimate(M,2);
delta = abs(length(shM) - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];

[shZ,~] = alignpulses2model(Z,shM);


%Generate third harmonic model

fprintf('Fitting third harmonic model\n')

thM = decimate(M,3);
delta = abs(length(thM) - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;
thM = [zeros(left_pad,1)',thM,zeros((right_pad),1)'];

[thZ,~] = alignpulses2model(Z,thM);


%Generate phase reversed model
fprintf('Fitting phase reversed model\n')

fhRM = -fhM;

[fhRZ,~] = alignpulses2model(Z,fhRM);
[fhRZ,~] = realign_abberant_peaks(fhRZ,fhRM);


%Generate phase reversed second harmonic model
fprintf('Fitting phase reversed second harmonic model\n')

shRM = -shM;

[shRZ,~] = alignpulses2model(Z,shRM);
[shRZ,~] = realign_abberant_peaks(shRZ,shRM);

%Generate phase reversed third harmonic model
fprintf('Fitting phase reversed third harmonic model\n')

thRM = -thM;

[thRZ,~] = alignpulses2model(Z,thRM);
[thRZ,~] = realign_abberant_peaks(thRZ,thRM);


for n=1:n_samples;
%calc chi-square for first model
    chisq(n,1) = ...
        mean((fhZ(n,:) - fhM).^2./var(fhZ(n,:)));
%calc chi-square for second harmonic model
    chisq(n,2) = ...
        mean((shZ(n,:) - shM).^2./var(shZ(n,:)));
%calc chi-square for third harmonic model
    chisq(n,3) = ...
        mean((thZ(n,:) - thM).^2./var(thZ(n,:)));    
%calc chi-square for reversed model
    chisq(n,4) = ...
        mean((fhRZ(n,:) - fhRM).^2./var(fhRZ(n,:)));
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

%%
%%This redefines fhZ to be only those data that fit fhM best
%%

%grab events that fit first harmonic model better
fhZ = Z(best_chisqr_idx == 1 | best_chisqr_idx == 4,:);
%grab events that fit second harmonic model better
%shZ = Z(best_chisqr_idx == 2 | best_chisqr_idx == 5,:);
%grab events that fit second harmonic model better
%thZ = Z(best_chisqr_idx == 3 | best_chisqr_idx == 6,:);

%%

%compare models with Lik analysis
%first make two de novo models from presumptive first and second harmonic
%data
%then, compare all data to each model with likelihood analysis

%de novo fit low freq model
%take mean of columns

%Build model of fh with fh data
fprintf('Fitting first harmonic model.\n');
[fhZ,fhM] = alignpulses(fhZ,20);
[fhZ,~] = realign_abberant_peaks(fhZ,fhM);

%Build second harmonic model
fprintf('Building second harmonic model\n')

shM = decimate(fhM,2);
delta = abs(length(shM) - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];

%Generate third harmonic model

fprintf('Building third harmonic model\n')

thM = decimate(fhM,3);
delta = abs(length(thM) - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;
thM = [zeros(left_pad,1)',thM,zeros((right_pad),1)'];

%Now realign all data to the  models
fprintf('Aligning all data to the models.\n');
[Z2fhM,fhM] = alignpulses2model(Z,fhM);
[Z2fhM,~] = realign_abberant_peaks(Z2fhM,fhM);

[Z2shM,shM] = alignpulses2model(Z,shM);
[Z2shM,~] = realign_abberant_peaks(Z2shM,shM);

[Z2thM,thM] = alignpulses2model(Z,thM);
[Z2thM,~] = realign_abberant_peaks(Z2thM,thM);


%Calc SE of samples at point of peak signal and
%find first and last points that exceed abs of this SE
% [~,samplepos] = max(fhM);
% st = std(Z2fhM(:,samplepos))/sqrt(n_samples);
% start=find(abs(fhM)>st,1,'first');
% finish=find(abs(fhM)>st,1,'last');


%compare SE at each point (from front and back) with deviation of model
%start and stop when deviation exceeds SE of data
S_Z2fhM = std(Z2fhM);
S_Z2shM = std(Z2shM);
S_Z2thM = std(Z2thM);

SE_Z2fhM = S_Z2fhM/sqrt(n_samples);
SE_Z2shM = S_Z2shM/sqrt(n_samples);
SE_Z2thM = S_Z2thM/sqrt(n_samples);

fh_start = find(abs(fhM>SE_Z2fhM),1,'first');
fh_finish = find(abs(fhM>SE_Z2fhM),1,'last');

sh_start = find(abs(shM>SE_Z2shM),1,'first');
sh_finish = find(abs(shM>SE_Z2shM),1,'last');

th_start = find(abs(thM>SE_Z2thM),1,'first');
th_finish = find(abs(thM>SE_Z2thM),1,'last');


%M = M(start:finish);
%Z = Z(:,start:finish);
%S = std(Z);

fhM = fhM(fh_start:fh_finish);
shM = shM(sh_start:sh_finish);
thM = thM(th_start:th_finish);
fhZ = fhZ(:,fh_start:fh_finish);
Z2fhM = Z2fhM(:,fh_start:fh_finish);
Z2shM = Z2shM(:,sh_start:sh_finish);
Z2thM = Z2thM(:,th_start:th_finish);

S_Z2fhM = S_Z2fhM(fh_start:fh_finish);
S_Z2shM = S_Z2shM(sh_start:sh_finish);
S_Z2thM = S_Z2thM(th_start:th_finish);


%M_ar = repmat(M,size(Z,1),1);
%S_ar = repmat(S,size(Z,1),1);
S_ar_fh = repmat(S_Z2fhM,size(Z2fhM,1),1);
S_ar_sh = repmat(S_Z2shM,size(Z2shM,1),1);
S_ar_th = repmat(S_Z2thM,size(Z2thM,1),1);
%d_pdf = sum(log10(normpdf(Z,M_ar,S_ar)),2);
%u_pdf = sum(log10(normpdf(Z,0,S_ar)),2);



%%%%
%%calculate likelihood of data under each model

fhM_ar = repmat(fhM,size(Z2fhM,1),1);
LL_fhM = sum(log10(normpdf(Z2fhM,fhM_ar,S_ar_fh)),2);
LL_0_fhpdf = sum(log10(normpdf(Z2fhM,0,S_ar_fh)),2);

shM_ar = repmat(shM,size(Z2shM,1),1);
LL_shM = sum(log10(normpdf(Z2shM,shM_ar,S_ar_sh)),2);
LL_0_shpdf = sum(log10(normpdf(Z2shM,0,S_ar_sh)),2);

thM_ar = repmat(thM,size(Z2thM,1),1);
LL_thM = sum(log10(normpdf(Z2thM,thM_ar,S_ar_th)),2);
LL_0_thpdf = sum(log10(normpdf(Z2thM,0,S_ar_th)),2);


LLR_fh = LL_fhM - LL_0_fhpdf;
LLR_sh = LL_shM - LL_0_shpdf;
LLR_th = LL_thM - LL_0_thpdf;


%Take best LLR
best_LLR = max(LLR_fh,LLR_sh);
best_LLR = max(best_LLR,LLR_th);


pulse_model.fhM = fhM;
pulse_model.shM = shM;
pulse_model.thM = thM;
pulse_model.fhZ = fhZ;%aligned pulses that fit first harmonic best
pulse_model.Z = Z2fhM;%aligned all pulses to first harmonic model
%pulse_model.S = S_Z2fhM;
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


