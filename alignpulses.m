function [Aligned_pulses,Model] = alignpulses(array,reps)
%[Model,Aligned_pulses] = alignpulses(array,reps)

%take mean of columns
Z = array;
M = mean(Z);
[n_samples,total_length] = size(Z);
%fprintf('Aligning "true" pulses to build model.\n');
for kk=1:reps;
    fprintf('Cycle %d.\n', kk);
    for n=1:n_samples;
        C = xcorr(M,Z(n,:),'unbiased');
        [~,tpeak] = max(C);
        tpeak = tpeak - total_length;
        Z(n,:) = circshift(Z(n,:),[1 tpeak]);
        a = mean(M.*Z(n,:))/mean(Z(n,:).^2);
        Z(n,:) = a*Z(n,:);
    end
    M = mean(Z);
end
scale = sqrt(mean(M.^2));
M = M/scale;
Z = Z/scale;
Model = M;
Aligned_pulses = Z;

