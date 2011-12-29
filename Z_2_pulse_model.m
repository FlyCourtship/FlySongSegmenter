function [pulse_model,Lik_pulse] = Z_2_pulse_model(pulse_model,new_pulses)

%[pulse_model,Lik_pulse] = Z_2_pulse_model(pulse_model,new_pulses)
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

%e.g.
% pulse_model = 
% 
%       fhM: [1x150 double]
%       shM: [1x150 double]
%       thM: [1x150 double]
%       fhZ: [503x150 double]
%       shZ: [79x150 double]
%       thZ: [30x150 double]
%     Z2fhM: [634x150 double]
%     Z2shM: [634x150 double]
%     Z2thM: [634x150 double]
%
% new_pulses = pulseInfo.x


fhM = pulse_model.fhM;
shM = pulse_model.shM;
thM = pulse_model.thM;

fhZ = pulse_model.fhZ;
shZ = pulse_model.shZ;
thZ = pulse_model.thZ;

d = new_pulses;

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


%
%pad models to accomodate length of new data
%
delta = abs(total_length - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;

fhZ = [zeros(size(fhZ,1),left_pad) fhZ zeros(size(fhZ,1),right_pad)];
shZ = [zeros(size(shZ,1),left_pad) shZ zeros(size(shZ,1),right_pad)];
thZ = [zeros(size(thZ,1),left_pad) thZ zeros(size(thZ,1),right_pad)];

fhM = [zeros(left_pad,1)',fhM,zeros((right_pad),1)'];
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];
thM = [zeros(left_pad,1)',thM,zeros((right_pad),1)'];


%align new data to old models

Z2fhM = alignpulses2model(Z,fhM);
Z2fhM = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(Z,shM);
Z2shM = scaleZ2M(Z2shM,shM);

Z2thM = alignpulses2model(Z,thM);
Z2thM = scaleZ2M(Z2thM,thM);

%Generate phase reversed model

fhRM = -fhM;

Z2fhRM = alignpulses2model(Z,fhRM);
Z2fhRM = scaleZ2M(Z2fhRM,fhRM);

%Generate phase reversed second harmonic model

shRM = -shM;

Z2shRM = alignpulses2model(Z,shRM);
Z2shRM = scaleZ2M(Z2shRM,shRM);

%Generate phase reversed third harmonic model

thRM = -thM;

Z2thRM = alignpulses2model(Z,thRM);
Z2thRM = scaleZ2M(Z2thRM,thRM);


for n=1:n_samples;
%calc chi-square for first model
    chisq(n,1) = ...
        mean((Z2fhM(n,:) - fhM).^2./var(Z2fhM(n,:)));
%calc chi-square for second harmonic model
    chisq(n,2) = ...
        mean((Z2shM(n,:) - shM).^2./var(Z2shM(n,:)));
%calc chi-square for third harmonic model
    chisq(n,3) = ...
        mean((Z2thM(n,:) - thM).^2./var(Z2thM(n,:)));    
%calc chi-square for reversed model
    chisq(n,4) = ...
        mean((Z2fhRM(n,:) - fhRM).^2./var(Z2fhRM(n,:)));
%calc chi-square for reversed second harmonic model
    chisq(n,5) = ...
        mean((Z2shRM(n,:) - shRM).^2./var(Z2shRM(n,:)));
%calc chi-square for reversed third harmonic model
    chisq(n,6) = ...
        mean((Z2thRM(n,:) - thRM).^2./var(Z2thRM(n,:)));    

end

[best_chisqr,best_chisqr_idx] = min(chisq,[],2);

%flip data that fits a reversed model better (columns 3 or 4)
for n=1:n_samples
    if best_chisqr_idx(n) > 3
        Z(n,:) = -Z(n,:);
    end
end


%Now realign all data to the  models
fprintf('Aligning all data to the models.\n');
Z2fhM = alignpulses2model(Z,fhM);
Z2fhM = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(Z,shM);
Z2shM = scaleZ2M(Z2shM,shM);

Z2thM = alignpulses2model(Z,thM);
Z2thM = scaleZ2M(Z2thM,thM);


%trim data to length of original models
%compare SE at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data

start = find(abs(fhM>0),1,'first');
finish = find(abs(fhM>0),1,'last');

fhM = fhM(start:finish);
shM = shM(start:finish);
thM = thM(start:finish);


fhZ = fhZ(:,start:finish);
shZ = shZ(:,start:finish);
thZ = thZ(:,start:finish);

Z2fhM = Z2fhM(:,start:finish);
Z2shM = Z2shM(:,start:finish);
Z2thM = Z2thM(:,start:finish);


%Get standard deviation at each point

S_fhM = std(fhZ);
S_shM = std(shZ);
S_thM = std(thZ);

%M_ar = repmat(M,size(Z,1),1);
%S_ar = repmat(S,size(Z,1),1);
S_ar_fh = repmat(S_fhM,size(Z2fhM,1),1);
S_ar_sh = repmat(S_shM,size(Z2shM,1),1);
S_ar_th = repmat(S_thM,size(Z2thM,1),1);
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
pulse_model.Z2fhM = Z2fhM;%aligned all pulses to first harmonic model
pulse_model.Z2shM = Z2shM;%aligned all pulses to first harmonic model
pulse_model.Z2thM = Z2thM;%aligned all pulses to first harmonic model
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


