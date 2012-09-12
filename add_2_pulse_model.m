function new_pulse_model = add_2_pulse_model(pulse_model,new_pulses)

%update a pulse model with additional data
%new_pulse_model = add_2_pulse_model(pulse_model,new_pulses)
%USAGE
%
%provide sample of pulses
%return pulse model & std etc and Lik of individual pulses given the model

%fit_pulse_model estimates only the fundamental frequency model using data
%that best fits this model. It then decimates the model and best fits data
%to build the second harmonic models for likelihood testing

%e.g.
% pulse_model = 
% 
%       fhM: [1x150 double]
%       shM: [1x150 double]
%       fhZ: [503x150 double]
%       shZ: [79x150 double]
%     Z2fhM: [634x150 double]
%     Z2shM: [634x150 double]
%
% new_pulses = pulseInfo.x


fprintf('Fitting new data to pulse model\n')

fhM = pulse_model.fhM;
shM = pulse_model.shM;

fhZ = pulse_model.fhZ;
shZ = pulse_model.shZ;

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
%pad old data
%
delta = abs(total_length - length(fhM));
left_pad = round(delta/2);
right_pad = delta -left_pad;

fhZ = [zeros(size(fhZ,1),left_pad) fhZ zeros(size(fhZ,1),right_pad)];
shZ = [zeros(size(shZ,1),left_pad) shZ zeros(size(shZ,1),right_pad)];


%[fhZ,fhM] = alignpulses(Z,20);

fhM = [zeros(left_pad,1)',fhM,zeros((right_pad),1)'];
shM = [zeros(left_pad,1)',shM,zeros((right_pad),1)'];


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

%use rem(number,2) to determine if even (false =0) or odd (true = 1)

%%
%%This redefines fhZ to be only those data that fit fhM best
%%

%grab events that are reasonable fits (chisq < 1.5) and fit first harmonic model better
fhZ4M = Z(best_chisqr <1.5 & best_chisqr_idx == 1 | best_chisqr_idx == 3,:);
%grab events that fit second harmonic model better
%shZ = Z(best_chisqr_idx == 2 | best_chisqr_idx == 5,:);
shZ4M = Z(best_chisqr <1.5 & best_chisqr_idx == 2 | best_chisqr_idx == 4,:);

%
%concatenate old and new data for each model
%


fhZ4M = cat(1,fhZ4M,fhZ);
shZ4M = cat(1,shZ4M,shZ);


%compare models with Lik analysis
%first make  de novo models from presumptive first harmonic data
%then, compare all data to each model with likelihood analysis

%de novo fit low freq model
%take mean of columns

%Build model of fh with fh data
fprintf('Fitting first harmonic model.\n');
%fhZ4M == goof fhZ used to build
[fhZ4M,fhM] = alignpulses(fhZ4M,20);

%Build second harmonic model
fprintf('Building second harmonic model\n')

[shZ4M,shM] = alignpulses(shZ4M,20);


%compare SE at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
S_Z = std(Z2fhM(Z2fhM ~= 0));%take only data that are not 0 (i.e. padding)
SE_Z = S_Z/sqrt(n_samples);

start = find(abs(fhM>SE_Z),1,'first');
finish = find(abs(fhM>SE_Z),1,'last');

fhM = fhM(start:finish);
shM = shM(start:finish);

fhZ4M = fhZ4M(:,start:finish);
shZ4M = shZ4M(:,start:finish);


new_pulse_model.fhM = fhM;
new_pulse_model.shM = shM;
new_pulse_model.fhZ = fhZ4M;%aligned pulses that fit first harmonic best
new_pulse_model.shZ = shZ4M;%aligned pulses that fit first harmonic best

