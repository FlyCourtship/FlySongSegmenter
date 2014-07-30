function [new_pulse_model,Lik_pulse] = FitPulseModel(pulse_model,new_pulses,sample_freqs)

%Fit new data to a pulse model
%[pulse_model,Lik_pulse] = FitPulseModel(pulse_model,new_pulses)
%[pulse_model,Lik_pulse] = FitPulseModel(pulse_model,new_pulses,sample_freqs)
%USAGE
%If the model and data were sampled at different sampling frequnecies, then
%enter this in sample_freqs
%sample_freqs e.g. [1e4 4e4] as the freqs for the model and new_pulses
%
%provide sample of pulses
%return pulse model & std etc and Lik of individual pulses given the model


%fit_pulse_model estimates only the fundamental frequency model using data
%that best fits this model. It then decimates the model and best fit data
%to build the second harmonic models for likelihood testing

%e.g.
% pulse_model = 
% 
%     fhM: [1x183 double]
%     shM: [1x168 double]
%     fhS: [1x183 double]
%     shS: [1x168 double]
%
% new_pulses = pulseInfo.x


       
if isempty(new_pulses);%if no pulses passed, send back empty arrays
    new_pulse_model.newfhM = [];
    new_pulse_model.newshM = [];
    new_pulse_model.newfhS = [];
    new_pulse_model.newshS = [];
    
    new_pulse_model.allZ2oldfhM = [];%aligned all pulses to old first harmonic model
    new_pulse_model.allZ2oldshM = [];%aligned all pulses to old second harmonic model
    
    %return LLR of pulses to old models
    Lik_pulse.LLR_best = [];
    Lik_pulse.LLR_fh = [];
    Lik_pulse.LLR_sh = [];
    return
end



fhM = pulse_model.fhM;
shM = pulse_model.shM;
lengthfhM = length(fhM);
lengthshM = length(shM);

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

%pad models

fhPad = round(lengthfhM /2);
shPad = round(lengthshM /2);

fhM = [zeros(fhPad,1)', fhM , zeros(fhPad,1)'];
shM = [zeros(shPad,1)', shM , zeros(shPad,1)'];

if isfield(pulse_model,'fhS')
    fhS = [zeros(fhPad,1)', fhS , zeros(fhPad,1)'];
    shS = [zeros(shPad,1)', shS , zeros(shPad,1)']; 
else
    fhZ = [zeros(size(fhZ,1),fhPad,1), fhZ , zeros(size(fhZ,1),fhPad,1)];
    shZ = [zeros(size(shZ,1),shPad,1), shZ , zeros(size(shZ,1),shPad,1)];
end



%double check to ensure lengths of model and data are equal
%first harmonic first
if ~isequal(total_length,length(fhM))
    diff = total_length - length(fhM);
    if diff > 1 %if data longer than model, add zeros(diff,1) to end of model
        fhM = [fhM, zeros(diff,1)'];
        fhS = [fhS, zeros(diff,1)'];
    else %add zeros to end of data
        Z = [Z,zeros(size(Z,1),-diff)];%take neg diff, because is neg
    end
end
%then second harmonic
if ~isequal(size(Z,2),length(shM))
    diff = size(Z,2) - length(shM);
    if diff > 1 %if data longer than model
        shM = [shM, zeros(diff,1)'];
        shS = [shS, zeros(diff,1)'];
    else %this is a very unlikely scenario, go ahead and trim second harmonic model is somehow longer than data
        if mod(diff,2)%if diff is odd 
            left_trim =round(diff/2);
            right_trim = left_trim - 1 ;
            shM = shM(left_trim:end-right_trim);
            shS = shS(left_trim:end-right_trim);
        else
            trim = diff/2;
            shM= shM(trim:end-trim);
            shS= shS(trim:end-trim);
        end
    end
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

[best_chisqr,best_chisqr_idx] = min(chisq,[],2);

%flip data that fits a reversed model better (columns 3 or 4)
for n=1:n_samples
    if best_chisqr_idx(n) > 2
        Z(n,:) = -Z(n,:);
    end
end


%Now realign all data to the  models
%fprintf('Aligning all data to the models.\n');
Z2fhM = alignpulses2model(Z,fhM);
Z2fhM = scaleZ2M(Z2fhM,fhM);

Z2shM = alignpulses2model(Z,shM);
Z2shM = scaleZ2M(Z2shM,shM);


%trim data and model down to relevant parts (no padding) for first harmonic

%If length of original data is longer than model
%then trim data to length of original models

%if data longer than model, just trim to model
if max_length > lengthfhM %max_length is from data (Z)
    startM = find(abs(fhM)>0,1,'first');
    finishM = find(abs(fhM)>0,1,'last');
    fhM = fhM(startM:finishM);
    if isfield(pulse_model,'fhS')
        fhS = fhS(startM:finishM);
    else
        fhZ = fhZ(:,startM:finishM);
    end    

    Z2fhM = Z2fhM(:,startM:finishM);

%if model longer than data, trim as follows
%compare SE of Z at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
elseif max_length < lengthfhM
    %if model is longer than data, then trim model
    %compare SE at each point (from front and back) with deviation of fh model
    %start and stop when deviation exceeds SE of data
    S_Z = std(Z2fhM(Z2fhM ~= 0));%take only data that are not 0 (i.e. padding)
    SE_Z = S_Z/sqrt(n_samples);
    startZ = find((abs(mean(Z2fhM))>SE_Z),1,'first');
    finishZ = find((abs(mean(Z2fhM))>SE_Z),1,'last');
    fhM = fhM(startZ:finishZ);
    if isfield(pulse_model,'fhS')
        fhS = fhS(startZ:finishZ);
    else
        fhZ = fhZ(:,startZ:finishZ);
    end
    Z2fhM = Z2fhM(:,startZ:finishZ);
end

%trim data and model down to relevant parts (no padding) for second harmonic

if max_length > lengthshM %max_length is from data (Z)
    startM = find(abs(shM)>0,1,'first');
    finishM = find(abs(shM)>0,1,'last');
    shM = shM(startM:finishM);
    if isfield(pulse_model,'fhS')
        shS = shS(startM:finishM);
    else
        shZ = shZ(:,startM:finishM);
    end    
    Z2shM = Z2shM(:,startM:finishM);

%if model longer than data, trim as follows
%compare SE of Z at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
elseif max_length < lengthshM
    %if model is longer than data, then trim model
    %compare SE at each point (from front and back) with deviation of fh model
    %start and stop when deviation exceeds SE of data
    S_Z = std(Z2shM(Z2shM ~= 0));%take only data that are not 0 (i.e. padding)
    SE_Z = S_Z/sqrt(n_samples);
    startZ = find((abs(mean(Z2shM))>SE_Z),1,'first');
    finishZ = find((abs(mean(Z2shM))>SE_Z),1,'last');
    shM = shM(startZ:finishZ);
    if isfield(pulse_model,'fhS')
        shS = shS(startZ:finishZ);
    else
        shZ = shZ(:,startZ:finishZ);
    end
    Z2shM = Z2shM(:,startZ:finishZ);
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




%calculate new pulse models with pulses that fit first and second harmonic
%best and return these

%grab events that are reasonable fits (chisq < 1.5) and fit first harmonic model better
fhZ4M = Z2fhM(best_chisqr <1.5 & best_chisqr_idx == 1 | best_chisqr_idx == 3,:);
%grab events that fit second harmonic model better
shZ4M = Z2shM(best_chisqr <1.5 & best_chisqr_idx == 2 | best_chisqr_idx == 4,:);


%Build model of fh with fh data
if size(fhZ4M,1)>1
    fprintf('Fitting first harmonic model.\n');
    %nfhM is new fhM fit to fhZ4M
    [fhZ4M,nfhM] = alignpulses(fhZ4M,20);
        
    %compare SE at each point (from front and back) with deviation of fh model
    %start and stop when deviation exceeds SE of data
    S_Z = std(fhZ4M(fhZ4M ~= 0));%take only data that are not 0 (i.e. padding)
    SE_Z = S_Z/sqrt(n_samples);
    
    start = find((abs(fhM)>SE_Z),1,'first');
    finish = find((abs(fhM)>SE_Z),1,'last');
    
    nfhM  = nfhM(start:finish);
	fhZ4M = fhZ4M(:,start:finish);
    
    %Get standard deviation at each point
    S_fhZ4M = std(fhZ4M);
    
else
    nfhM = [];
    S_fhZ4M = [];
end

%Build second harmonic model
if size(shZ4M,1)>1
    
    fprintf('Building second harmonic model\n')
    
    [shZ4M,nshM] = alignpulses(shZ4M,20);
        
    %compare SE at each point (from front and back) with deviation of fh model
    %start and stop when deviation exceeds SE of data
    S_Z = std(shZ4M(shZ4M ~= 0));%take only data that are not 0 (i.e. padding)
    SE_Z = S_Z/sqrt(n_samples);
    
    start = find((abs(shM)>SE_Z),1,'first');
    finish = find((abs(shM)>SE_Z),1,'last');
    
    nshM  = nshM(start:finish);    
    shZ4M = shZ4M(:,start:finish);
    
    %Get standard deviation at each point
    
    S_shZ4M = std(shZ4M);
    
else
    nshM = [];
    S_shZ4M = [];
end

new_pulse_model.newfhM = nfhM;
new_pulse_model.newshM = nshM;
new_pulse_model.newfhS = S_fhZ4M;
new_pulse_model.newshS = S_shZ4M;

new_pulse_model.allZ2oldfhM = Z2fhM;%aligned all pulses to old first harmonic model
new_pulse_model.allZ2oldshM = Z2shM;%aligned all pulses to old second harmonic model

%return LLR of pulses to old models
Lik_pulse.LLR_best = best_LLR;
Lik_pulse.LLR_fh = LLR_fh;
Lik_pulse.LLR_sh = LLR_sh;

