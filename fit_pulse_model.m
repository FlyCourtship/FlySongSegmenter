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
%fhZ = realign_abberant_peaks(fhZ,fhM);


%Generate second harmonic model
fprintf('Fitting second harmonic model\n')

shM = decimate(fhM,2);
delta = abs(length(shM) - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];

shZ = alignpulses2model(fhZ,shM);
shZ = scaleZ2M(shZ,fhM);

% %Generate third harmonic model
% 1 Jan 2011 - After further exploration, I find no evidence that the third
% harmonic provides a suitable model for any real pulses. Fits only some
% noise better. Delete all third harmonic modeling from code
% 
% fprintf('Fitting third harmonic model\n')
% 
% thM = decimate(fhM,3);
% delta = abs(length(thM) - length(fhM));
% left_pad = round(delta/2);
% right_pad = delta -left_pad;
% thM = [zeros(left_pad,1)',thM,zeros((right_pad),1)'];
% 
% thZ = alignpulses2model(fhZ,thM);
% thZ = scaleZ2M(thZ,fhM);

%Generate phase reversed model
fprintf('Fitting phase reversed model\n')

fhRM = -fhM;

fhRZ = alignpulses2model(Z,fhRM);
fhRZ  = scaleZ2M(fhRZ,fhRM);

%Generate phase reversed second harmonic model
fprintf('Fitting phase reversed second harmonic model\n')

shRM = -shM;

shRZ = alignpulses2model(Z,shRM);
shRZ  = scaleZ2M(shRZ,shRM);

% %Generate phase reversed third harmonic model
% fprintf('Fitting phase reversed third harmonic model\n')
% 
% thRM = -thM;
% 
% thRZ = alignpulses2model(Z,thRM);
% thRZ  = scaleZ2M(thRZ,thRM);


for n=1:n_samples;
%calc chi-square for first model
    chisq(n,1) = ...
        mean((fhZ(n,:) - fhM).^2./var(fhZ(n,:)));
%calc chi-square for second harmonic model
    chisq(n,2) = ...
        mean((shZ(n,:) - shM).^2./var(shZ(n,:)));
% %calc chi-square for third harmonic model
%     chisq(n,3) = ...
%         mean((thZ(n,:) - thM).^2./var(thZ(n,:)));    
%calc chi-square for reversed model
    chisq(n,3) = ...
        mean((fhRZ(n,:) - fhRM).^2./var(fhRZ(n,:)));
%calc chi-square for reversed second harmonic model
    chisq(n,4) = ...
        mean((shRZ(n,:) - shRM).^2./var(shRZ(n,:)));
% %calc chi-square for reversed third harmonic model
%     chisq(n,6) = ...
%         mean((thRZ(n,:) - thRM).^2./var(thRZ(n,:)));    

end

[best_chisqr,best_chisqr_idx] = min(chisq,[],2);

%flip data that fits a reversed model better (columns 3 or 4)
for n=1:n_samples
    if best_chisqr_idx(n) > 2
        Z(n,:) = -Z(n,:);
    end
end

%use rem(number,2) to determine if even (false =0) or odd (true = 1)

%%
%%This redefines fhZ to be only those data that fit fhM best
%%

%grab events that are reasonable fits (chisq < 1.5) and fit first harmonic model better
fhZ4M = fhZ(best_chisqr <1.5 & best_chisqr_idx == 1 | best_chisqr_idx == 3,:);
%grab events that fit second harmonic model better
%shZ = Z(best_chisqr_idx == 2 | best_chisqr_idx == 5,:);
shZ4M = fhZ(best_chisqr <1.5 & best_chisqr_idx == 2 | best_chisqr_idx == 4,:);
%grab events that fit second harmonic model better
%thZ = Z(best_chisqr_idx == 3 | best_chisqr_idx == 6,:);
%thZ4M = fhZ(best_chisqr <1.5 & best_chisqr_idx == 3 | best_chisqr_idx == 6,:);

%%

%compare models with Lik analysis
%first make  de novo models from presumptive first harmonic data
%then, compare all data to each model with likelihood analysis

%de novo fit low freq model
%take mean of columns

%Build model of fh with fh data
fprintf('Fitting first harmonic model.\n');
%fhZ4M == goof fhZ used to build
%nfhM is new fhM fit to fhZ4M
[fhZ4M,nfhM] = alignpulses(fhZ4M,20);
%fhZ4M = realign_abberant_peaks(fhZ4M,fhM);

%Build second harmonic model
fprintf('Building second harmonic model\n')

[shZ4M,nshM] = alignpulses(shZ4M,20);
%shZ4M = realign_abberant_peaks(shZ4M,shM);

%Generate third harmonic model

% fprintf('Building third harmonic model\n')
% 
% [thZ4M,nthM] = alignpulses(thZ4M,20);
%thZ4M = realign_abberant_peaks(thZ4M,thM);



%Now realign all data to the  models
fprintf('Aligning all data to the models.\n');
Z2fhM = alignpulses2model(fhZ,fhM);
Z2fhM  = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(fhZ,shM);
Z2shM  = scaleZ2M(Z2shM,shM);

% Z2thM = alignpulses2model(fhZ,thM);
% Z2thM  = scaleZ2M(Z2thM,thM);

Z2nfhM = alignpulses2model(fhZ,nfhM);
Z2nfhM  = scaleZ2M(Z2nfhM,nfhM);

Z2nshM = alignpulses2model(fhZ,nshM);
Z2nshM  = scaleZ2M(Z2nshM,nshM);

% Z2nthM = alignpulses2model(fhZ,nthM);
% Z2nthM  = scaleZ2M(Z2nthM,nthM);


%compare SE at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
S_Z = std(Z2fhM(Z2fhM ~= 0));%take only data that are not 0 (i.e. padding)
SE_Z = S_Z/sqrt(n_samples);

start = find(abs(fhM>SE_Z),1,'first');
finish = find(abs(fhM>SE_Z),1,'last');

fhM = fhM(start:finish);
shM = shM(start:finish);
% thM = thM(start:finish);
nfhM  = nfhM(start:finish);
nshM  = nshM(start:finish);
% nthM = nthM(start:finish);

fhZ4M = fhZ4M(:,start:finish);
shZ4M = shZ4M(:,start:finish);
% thZ4M = thZ4M(:,start:finish);

Z2fhM = Z2fhM(:,start:finish);
Z2shM = Z2shM(:,start:finish);
% Z2thM = Z2thM(:,start:finish);
Z2nfhM = Z2nfhM(:,start:finish);
Z2nshM = Z2nshM(:,start:finish);
% Z2nthM = Z2nthM(:,start:finish);


%Get standard deviation at each point

S_Z2fhM = std(Z2fhM);
S_Z2shM = std(Z2shM);
% S_Z2thM = std(Z2thM);
S_Z2nfhM = std(Z2nfhM);
S_Z2nshM = std(Z2nshM);
% S_Z2nthM = std(Z2nthM);

%M_ar = repmat(M,size(Z,1),1);
%S_ar = repmat(S,size(Z,1),1);
S_ar_fh = repmat(S_Z2fhM,size(Z2fhM,1),1);
S_ar_sh = repmat(S_Z2shM,size(Z2shM,1),1);
% S_ar_th = repmat(S_Z2thM,size(Z2thM,1),1);
S_ar_nfh = repmat(S_Z2nfhM,size(Z2nfhM,1),1);
S_ar_nsh = repmat(S_Z2nshM,size(Z2nshM,1),1);
% S_ar_nth = repmat(S_Z2nthM,size(Z2nthM,1),1);
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

% thM_ar = repmat(thM,size(Z2thM,1),1);
% LL_thM = sum(log10(normpdf(Z2thM,thM_ar,S_ar_th)),2);
% LL_0_thpdf = sum(log10(normpdf(Z2thM,0,S_ar_th)),2);

nfhM_ar = repmat(nfhM,size(Z2nfhM,1),1);
LL_nfhM = sum(log10(normpdf(Z2nfhM,nfhM_ar,S_ar_nfh)),2);
LL_0_nfhpdf = sum(log10(normpdf(Z2nfhM,0,S_ar_nfh)),2);

nshM_ar = repmat(nshM,size(Z2nshM,1),1); 
LL_nshM = sum(log10(normpdf(Z2nshM,nshM_ar,S_ar_nsh)),2);
LL_0_nshpdf = sum(log10(normpdf(Z2nshM,0,S_ar_nsh)),2);

% nthM_ar = repmat(nthM,size(Z2nthM,1),1);
% LL_nthM = sum(log10(normpdf(Z2nthM,nthM_ar,S_ar_nth)),2);
% LL_0_nthpdf = sum(log10(normpdf(Z2nthM,0,S_ar_nth)),2);

LLR_fh = LL_fhM - LL_0_fhpdf;
LLR_sh = LL_shM - LL_0_shpdf;
% LLR_th = LL_thM - LL_0_thpdf;

LLR_nfh = LL_nfhM - LL_0_nfhpdf;
LLR_nsh = LL_nshM - LL_0_nshpdf;
% LLR_nth = LL_nthM - LL_0_nthpdf;


%Take best LLR
best_LLR = max(LLR_nfh,LLR_nsh);
% best_LLR = max(best_LLR,LLR_nth);


pulse_model.fhM = nfhM;
pulse_model.shM = nshM;
% pulse_model.thM = thM;
% pulse_model.nfhM = nfhM;
% pulse_model.nshM = nshM;
% pulse_model.nthM = nthM;
pulse_model.fhZ = fhZ4M;%aligned pulses that fit first harmonic best
pulse_model.shZ = shZ4M;%aligned pulses that fit first harmonic best
% pulse_model.thZ = thZ4M;%aligned pulses that fit first harmonic best
pulse_model.Z2fhM = Z2nfhM;%aligned all pulses to first harmonic model
pulse_model.Z2shM = Z2nshM;%aligned all pulses to first harmonic model
% pulse_model.Z2thM = Z2thM;%aligned all pulses to first harmonic model
% pulse_model.Z2nfhM = Z2nfhM;%aligned all pulses to first harmonic model
% pulse_model.Z2nshM = Z2nshM;%aligned all pulses to first harmonic model
% pulse_model.Z2nthM = Z2nthM;%aligned all pulses to first harmonic model

Lik_pulse.LLR_best = best_LLR;
Lik_pulse.LLR_fh = LLR_nfh;
Lik_pulse.LLR_sh = LLR_nsh;
% Lik_pulse.LLR_nth = LLR_nth;
% Lik_pulse.LLR_fh = LLR_fh;
% Lik_pulse.LLR_sh = LLR_sh;
% Lik_pulse.LLR_th = LLR_th;
%Lik_pulse.d_pdf = d_pdf;
%Lik_pulse.u_pdf = u_pdf;
%Lik_pulse.d_rev_pdf = d_rev_pdf;


