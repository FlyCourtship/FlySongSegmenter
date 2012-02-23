function [pulse_model,Lik_pulse] = Z_2_pulse_model(pulse_model,new_pulses,sample_freqs)

%[pulse_model,Lik_pulse] = Z_2_pulse_model(pulse_model,new_pulses)
%[pulse_model,Lik_pulse] = Z_2_pulse_model(pulse_model,new_pulses,sample_freqs)
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
lengthfhM = length(fhM);
shM  = length(shM);

if isfield(pulse_model,'fhS')
    fhS = pulse_model.fhS;
    shS = pulse_model.shS;
else
    fhZ = pulse_model.fhZ;
    shZ = pulse_model.shZ;
end



%resample model and data to coordinate sample frequencies with new data
%
if nargin == 3 %if user provides sampling frequencies
%    sfs = sample_freqs;%e.g. [1e4 4e4] as the freqs for the model and new_pulses
    fsM = sample_freqs(1);
    fsZ = sample_freqs(2);
    ratio = fsZ/fsM;
    new_length = length(fhM) * ratio;
    fhM = interpft(fhM,new_length);
    shM = interpft(shM,new_length);
    if isfield(pulse_model,'fhS')
        fhS = interpft(fhS,new_length);
        shS = interpft(shS,new_length);
    else
        fhZ = interpft(fhZ,new_length,2);
        shZ = interpft(shZ,new_length,2);
    end
end

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
delta = abs(total_length - lengthfhM);
left_pad = round(delta/2);
right_pad = delta -left_pad;
if total_length > lengthfhM
    %if new data is longer than model
    %pad model
    fhM = [zeros(left_pad,1)',fhM,zeros((right_pad),1)'];
    shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];
    if isfield(pulse_model,'fhS')
        fhS = [zeros(left_pad,1)',fhS,zeros((right_pad),1)'];
        shS = [zeros(left_pad,1)',shS,zeros((right_pad),1)'];
    else
        fhZ = [zeros(size(fhZ,1),left_pad) fhZ zeros(size(fhZ,1),right_pad)];
        shZ = [zeros(size(shZ,1),left_pad) shZ zeros(size(shZ,1),right_pad)];
    end

    
elseif lengthfhM > total_length
    %if model is longer than data
    %pad data
    Z = [zeros(size(Z,1),left_pad) Z zeros(size(Z,1),right_pad)];
end
        

%align new data to old models

Z2fhM = alignpulses2model(Z,fhM);
Z2fhM = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(Z,shM);
Z2shM = scaleZ2M(Z2shM,shM);

%Generate phase reversed model

fhRM = -fhM;

Z2fhRM = alignpulses2model(Z,fhRM);
Z2fhRM = scaleZ2M(Z2fhRM,fhRM);

%Generate phase reversed second harmonic model

shRM = -shM;

Z2shRM = alignpulses2model(Z,shRM);
Z2shRM = scaleZ2M(Z2shRM,shRM);


for n=1:n_samples;
%calc chi-square for first model
    chisq(n,1) = ...
        mean((Z2fhM(n,:) - fhM).^2./var(Z2fhM(n,:)));
%calc chi-square for second harmonic model
    chisq(n,2) = ...
        mean((Z2shM(n,:) - shM).^2./var(Z2shM(n,:)));
%calc chi-square for reversed model
    chisq(n,3) = ...
        mean((Z2fhRM(n,:) - fhRM).^2./var(Z2fhRM(n,:)));
%calc chi-square for reversed second harmonic model
    chisq(n,4) = ...
        mean((Z2shRM(n,:) - shRM).^2./var(Z2shRM(n,:)));
end

[~,best_chisqr_idx] = min(chisq,[],2);

%flip data that fits a reversed model better (columns 3 or 4)
for n=1:n_samples
    if best_chisqr_idx(n) > 2
        Z(n,:) = -Z(n,:);
    end
end


%Now realign all data to the  models
fprintf('Aligning all data to the models.\n');
Z2fhM = alignpulses2model(Z,fhM);
Z2fhM = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(Z,shM);
Z2shM = scaleZ2M(Z2shM,shM);


%If length of original data is longer than model
%then trim data to length of original models
%compare SE at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
if max_length > lengthfhM
    startM = find(abs(fhM>0),1,'first');
    finishM = find(abs(fhM>0),1,'last');
        
    Z2fhM = Z2fhM(:,startM:finishM);
    Z2shM = Z2shM(:,startM:finishM);
elseif max_length < lengthfhM
    %if model is longer than data, then trim model
    %compare SE at each point (from front and back) with deviation of fh model
    %start and stop when deviation exceeds SE of data
%     S_Z = std(Z2fhM(Z2fhM ~= 0));%take only data that are not 0 (i.e. padding)
%     SE_Z = S_Z/sqrt(n_samples);
%     
    [~,peakZidx] = max(mean(Z2fhM));
    [~,peakMidx] = max(fhM);
%     start = find(abs(Z2fhM>SE_Z),1,'first');
%     finish = find(abs(Z2fhM>SE_Z),1,'last');
    
    left = peakZidx - peakMidx;
    right = left + lengthfhM;
    if left > 0
        
        Z2fhM  = Z2fhM(left:right);
        Z2shM  = Z2shM(left:right);
    else
        
    end
end

%Get standard deviation at each point
if isfield(pulse_model,'fhS')
    S_fhM = fhS;
    S_shM = shS;
else
    S_fhM = std(fhZ);
    S_shM = std(shZ);
end

S_ar_fh = repmat(S_fhM,size(Z2fhM,1),1);
S_ar_sh = repmat(S_shM,size(Z2shM,1),1);

%%%%
%%calculate likelihood of data under each model

fhM_ar = repmat(fhM,size(Z2fhM,1),1);
LL_fhM = nansum(log10(normpdf(Z2fhM,fhM_ar,S_ar_fh)),2);
LL_0_fhpdf = nansum(log10(normpdf(Z2fhM,0,S_ar_fh)),2);

shM_ar = repmat(shM,size(Z2shM,1),1);
LL_shM = nansum(log10(normpdf(Z2shM,shM_ar,S_ar_sh)),2);
LL_0_shpdf = nansum(log10(normpdf(Z2shM,0,S_ar_sh)),2);

LLR_fh = LL_fhM - LL_0_fhpdf;
LLR_sh = LL_shM - LL_0_shpdf;


%Take best LLR
best_LLR = max(LLR_fh,LLR_sh);

pulse_model.fhM = fhM;
pulse_model.shM = shM;
pulse_model.Z2fhM = Z2fhM;%aligned all pulses to first harmonic model
pulse_model.Z2shM = Z2shM;%aligned all pulses to first harmonic model

Lik_pulse.LLR_best = best_LLR;
Lik_pulse.LLR_fh = LLR_fh;
Lik_pulse.LLR_sh = LLR_sh;

