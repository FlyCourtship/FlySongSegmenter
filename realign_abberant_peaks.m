function [Aligned_pulses,Model] = realign_abberant_peaks(Z,M);

[n_samples,total_length] = size(Z);
%fprintf('Double checking peak alignments.\n');

%get peak to trough distance
[~,peak] = max(M);
[~,trough] = min(M);
p2t = abs(peak - trough);

for n=1:n_samples;
    [~,sample_peak] = max(Z(n,:));
    %if peak is far from peak of M
    if sample_peak > p2t
        shift = peak - sample_peak;
        Z(n,:) = circshift(Z(n,:),[1 shift]);
    end
end
M = mean(Z);
scale = sqrt(mean(M.^2));
M = M/scale;
Z = Z/scale;
Model = M;
Aligned_pulses = Z;

