function ipi = fit_ipi_model(pulseInfo,fs)
%ipi = fit_ipi_model(pulseInfo,fs)
%provide pulses
%return info about ipis

%p are pulses (=pulseInfo2.wc)
fprintf('fitting ipi model\n')
p = pulseInfo.wc ./ fs;


%fit mixture model, take fit capturing most data
%first, grab all ipis

p_shift_one = circshift(p,[0 -1]);
ipi_d=p_shift_one(1:end-1)-p(1:end-1);
%Test range of gmdistribution.fit parameters
AIC=zeros(1,6);
obj=cell(1,6);
options = statset('MaxIter',500);
for k=1:6
    try
%        fprintf('iter\n')
        obj{k}=gmdistribution.fit(ipi_d',k,'options',options);
%        fprintf('iter2\n')
        
        if obj{k}.Converged == 1%keep AIC only for those that converged
            AIC(k)=obj{k}.AIC;
        end
    catch
                fprintf('problem\n')

    end
end
[~,numComponents]=min(AIC);%best fit model
try
    find(obj{1}.PComponents == max(obj{1}.PComponents));
    ipi_index = find(obj{numComponents}.PComponents == max(obj{numComponents}.PComponents));%find the model in the mixture model with the highest mixture proportion
    ipi_mean = obj{numComponents}.mu(ipi_index);
    ipi_var = obj{numComponents}.Sigma(ipi_index);
    ipi_SD = sqrt(ipi_var);
%
catch
    fprintf('Could not fit mixture model with winnowed ipis.\nI will use the estimates from the full data set.\n')
    %numComponents = length(ipi.fit.PComponents);
    obj = original_ipi.fit;
    ipi_index = find(obj.PComponents == max(obj.PComponents));%find the model in the mixture model with the highest mixture proportion
    ipi_mean = obj.mu(ipi_index);
    ipi_var = obj.Sigma(ipi_index);
    ipi_SD = sqrt(ipi_var);
    obj = {};
    obj{1} = original_ipi.fit;
end

ipi = struct('u',ipi_mean,'S',ipi_SD,'d',ipi_d,'fit',obj{numComponents});%results in units of samples