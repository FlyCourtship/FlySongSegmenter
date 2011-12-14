function [fZ,fM] = alignpulses2model(Z,M)

[n_samples,total_length] = size(Z);

for n = 1:n_samples;
    C = xcorr(M,Z(n,:),'unbiased');
    [~,tpeak] = max(C);
    tpeak = tpeak - total_length;
    Z(n,:) = circshift(Z(n,:),[1 tpeak]);
end

scale = sqrt(mean(M.^2));
fM = M/scale;
fZ = Z/scale;
