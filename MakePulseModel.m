function [pulse_model,Lik_pulse] = MakePulseModel(pulses)

%[pulse_model,Lik_pulse] = fit_pulse_model(pulses)
%USAGE
%
%provide sample of pulses
%return pulse model & std etc and Lik of individual pulses given the model

%fit_pulse_model estimates only the fundamental frequency model using data
%that best fits this model. It then decimates the model and best fit data
%to build the second harmonic models for likelihood testing

%d will often = pulseInfo2.x

fprintf('Fitting pulse model\n')
d = pulses;

%grab samples, center, and pad

n_samples = length(d);
max_length = max(cellfun(@length,d));
total_length = 2* max_length;
Z = zeros(n_samples,total_length );
if n_samples >1
    parfor n=1:n_samples;
        X = d{n};
        T = length(X);
        [~,C] = max(X);%get position of max power
        
        %center on max power
        left_pad = max_length - C;  %i.e. ((total_length/2) - C)
        right_pad = total_length - T - left_pad;
        Z(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
    end
    
    
    [fhZ,fhM] = alignpulses(Z,20);
        
    %Generate second harmonic model
    fprintf('Fitting second harmonic model\n')
    
    shM = decimate(fhM,2);
    delta = abs(length(shM) - length(fhM));
    left_pad = round(delta/2);
    right_pad = delta -left_pad;
    shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];
    
    shZ = alignpulses2model(fhZ,shM);
    shZ = scaleZ2M(shZ,fhM);
    
   
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
    
    
    chisq=zeros(n_samples,4);
    for n=1:n_samples;
        %calc chi-square for first model
        chisq(n,1) = ...
            mean((fhZ(n,:) - fhM).^2./var(fhZ(n,:)));
        %calc chi-square for second harmonic model
        chisq(n,2) = ...
            mean((shZ(n,:) - shM).^2./var(shZ(n,:)));
         %calc chi-square for reversed model
        chisq(n,3) = ...
            mean((fhRZ(n,:) - fhRM).^2./var(fhRZ(n,:)));
        %calc chi-square for reversed second harmonic model
        chisq(n,4) = ...
            mean((shRZ(n,:) - shRM).^2./var(shRZ(n,:)));
         
    end
    
    [best_chisqr,best_chisqr_idx] = min(chisq,[],2);
    
    %flip data that fits a reversed model better (columns 3 or 4)
    parfor n=1:n_samples
        if best_chisqr_idx(n) > 2
            fhZ(n,:) = -fhZ(n,:);
        end
    end
    
    
    
    %grab events that are reasonable fits (chisq < 1.5) and fit first harmonic model better
    fhZ4M = fhZ(best_chisqr <1.5 & best_chisqr_idx == 1 | best_chisqr_idx == 3,:);
    %grab events that fit second harmonic model better
    shZ4M = fhZ(best_chisqr <1.5 & best_chisqr_idx == 2 | best_chisqr_idx == 4,:);
     
    
    %compare models with Lik analysis
    %first make  de novo models from presumptive first harmonic data
    %then, compare all data to each model with likelihood analysis
    
    
    %Build model of fh with fh data
    if size(fhZ4M,1)>1
        fprintf('Fitting first harmonic model.\n');
        %fhZ4M == goof fhZ used to build
        %nfhM is new fhM fit to fhZ4M
        [fhZ4M,nfhM] = alignpulses(fhZ4M,20);
        %fhZ4M = realign_abberant_peaks(fhZ4M,fhM);
        
        %Now realign all data to the  models
        fprintf('Aligning all data to the models.\n');
        
        Z2nfhM = alignpulses2model(fhZ,nfhM);
        Z2nfhM  = scaleZ2M(Z2nfhM,nfhM);
        
        %compare SE at each point (from front and back) with deviation of fh model
        %start and stop when deviation exceeds SE of data
        S_Z = std(Z2nfhM(Z2nfhM ~= 0));%take only data that are not 0 (i.e. padding)
        SE_Z = S_Z/sqrt(n_samples);
        
        start = find((abs(fhM)>SE_Z),1,'first');
        finish = find((abs(fhM)>SE_Z),1,'last');
        
        nfhM  = nfhM(start:finish);
        
        
        fhZ4M = fhZ4M(:,start:finish);
        Z2nfhM = Z2nfhM(:,start:finish);
        
        %Get standard deviation at each point
        S_Z2nfhM = std(Z2nfhM);
        S_ar_nfh = repmat(S_Z2nfhM,size(Z2nfhM,1),1);
        %%%%
        %%calculate likelihood of data under each model
        
        
        nfhM_ar = repmat(nfhM,size(Z2nfhM,1),1);
        LL_nfhM = nansum(log10(normpdf(Z2nfhM,nfhM_ar,S_ar_nfh)),2);
        LL_0_nfhpdf = nansum(log10(normpdf(Z2nfhM,0,S_ar_nfh)),2);
        
        LLR_nfh = LL_nfhM - LL_0_nfhpdf;
        
        
    else
        nfhM = [];
        Z2nfhM = [];
        LLR_nfh = [];
    end
    
    %Build second harmonic model
    if size(shZ4M,1)>1
        
        fprintf('Building second harmonic model\n')
        
        [shZ4M,nshM] = alignpulses(shZ4M,20);
        
        %Now realign all data to the  models
        fprintf('Aligning all data to the models.\n');
        Z2nshM = alignpulses2model(fhZ,nshM);
        Z2nshM  = scaleZ2M(Z2nshM,nshM);
                
        %compare SE at each point (from front and back) with deviation of fh model
        %start and stop when deviation exceeds SE of data
        S_Z = std(Z2nshM(Z2nshM ~= 0));%take only data that are not 0 (i.e. padding)
        SE_Z = S_Z/sqrt(n_samples);
        
        start = find((abs(shM)>SE_Z),1,'first');
        finish = find((abs(shM)>SE_Z),1,'last');
  
        nshM  = nshM(start:finish);
        shZ4M = shZ4M(:,start:finish);
        
        Z2nshM = Z2nshM(:,start:finish);
        
        %Get standard deviation at each point
        
        S_Z2nshM = std(Z2nshM);
        S_ar_nsh = repmat(S_Z2nshM,size(Z2nshM,1),1);
        %%%%
        %%calculate likelihood of data under each model
        
        nshM_ar = repmat(nshM,size(Z2nshM,1),1);
        LL_nshM = nansum(log10(normpdf(Z2nshM,nshM_ar,S_ar_nsh)),2);
        LL_0_nshpdf = nansum(log10(normpdf(Z2nshM,0,S_ar_nsh)),2);
        LLR_nsh = LL_nshM - LL_0_nshpdf;
        
        
    else
        nshM = [];
        Z2nshM = [];
        LLR_nsh = [];
    end
    
    
    
    %Take best LLR
    if ~isempty(LLR_nfh) && ~isempty(LLR_nsh)
        best_LLR = max(LLR_nfh,LLR_nsh);
    elseif ~isempty(LLR_nfh)
        best_LLR = LLR_nfh;
    elseif ~isempty(LLR_nsh);
        best_LLR = LLR_nsh;
    end
    
    pulse_model.fhM = nfhM;
    pulse_model.shM = nshM;
    pulse_model.fhZ = fhZ4M;%aligned pulses that fit first harmonic best
    pulse_model.shZ = shZ4M;%aligned pulses that fit first harmonic best
    pulse_model.Z2fhM = Z2nfhM;%aligned all pulses to first harmonic model
    pulse_model.Z2shM = Z2nshM;%aligned all pulses to first harmonic model
    
    Lik_pulse.LLR_best = best_LLR;
    Lik_pulse.LLR_fh = LLR_nfh;
    Lik_pulse.LLR_sh = LLR_nsh;
    
else
    if n_samples == 0
        pulse_model.fhM = [];
        pulse_model.shM = [];
        pulse_model.fhZ = [];%aligned pulses that fit first harmonic best
        pulse_model.shZ = [];%aligned pulses that fit first harmonic best
        pulse_model.Z2fhM = [];%aligned all pulses to first harmonic model
        pulse_model.Z2shM = [];%aligned all pulses to first harmonic model
        
        Lik_pulse.LLR_best = [];
        Lik_pulse.LLR_fh = [];
        Lik_pulse.LLR_sh = [];
        
    end
    
    if n_samples == 1
        pulse_model.fhM = [];
        pulse_model.shM = [];
        pulse_model.fhZ = d{1};%aligned pulses that fit first harmonic best
        pulse_model.shZ = [];%aligned pulses that fit first harmonic best
        pulse_model.Z2fhM = [];%aligned all pulses to first harmonic model
        pulse_model.Z2shM = [];%aligned all pulses to first harmonic model
        
        Lik_pulse.LLR_best = [];
        Lik_pulse.LLR_fh = [];
        Lik_pulse.LLR_sh = [];
    end
end
