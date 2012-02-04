function [Aligned_pulses,Model] = alignpulses(array,reps)
%[Model,Aligned_pulses] = alignpulses(array,reps)
[poolavail,isOpen] = check_open_pool;
%take mean of columns
Z = array;
M = mean(Z);
[n_samples,total_length] = size(Z);

%uncomment to test performance of fit
%deviation = zeros(reps);
%fprintf('Aligning "true" pulses to build model.\n');
for kk=1:reps;
    %fprintf('Cycle %d.\n', kk);
    parfor n=1:n_samples;
        C = xcorr(M,Z(n,:),'unbiased');
        [~,tpeak] = max(C);
        tpeak = tpeak - total_length;
        Z(n,:) = circshift(Z(n,:),[1 tpeak]);
    end
    %rescale data to mean
    %equivalent to following, on whole array
    %a = mean(M.*Z(n,:))/mean(Z(n,:).^2);
    %Z(n,:) = a*Z(n,:);

    Ma = repmat(M,n_samples,1);
    num = mean(Ma'.*Z');
    den = mean(Z'.^2);
    a = num./den;
    ar = repmat(a',1,total_length);
    Z = ar.* Z;
    M = mean(Z);
    
    %to test for performance, check change in variance with reps
    %deviation(kk) = sum(var(Z));
    
end
scale = sqrt(mean(M.^2));
M = M/scale;
Z = Z/scale;
Model = M;
Aligned_pulses = Z;
check_close_pool(poolavail,isOpen);
