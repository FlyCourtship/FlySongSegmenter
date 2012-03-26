function ipi = fit_ipi_model(pulseTimes,numComponents)
%ipi = fit_ipi_model(pulseInfo)
%provide pulses
%return info about ipis, time in second (not samples)

%p are pulses (=pulseInfo2.wc)
fprintf('fitting ipi model\n')
%e.g. pulseTimes = pulseInfo.wc;
p = pulseTimes;

if nargin <2
    numComponents = 6;
end
% numComponents
%fit mixture model, take fit capturing most data
%first, grab all ipis

p_shift_one = circshift(p,[0 -1]);
ipi_d=p_shift_one(1:end-1)-p(1:end-1);
%Test range of gmdistribution.fit parameters
AIC=zeros(1,numComponents);
obj=cell(1,numComponents);
options = statset('MaxIter',500);
for k=1:numComponents
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

    ipi_time = p(1:end-1);
    ipi = struct('u',ipi_mean,'S',ipi_SD,'d',ipi_d,'t',ipi_time,'fit',obj{numComponents});%results in units of samples
%
catch
    fprintf('Could not fit mixture model with winnowed ipis.\n')
%     %numComponents = length(ipi.fit.PComponents);
%     obj = original_ipi.fit;
%     ipi_index = find(obj.PComponents == max(obj.PComponents));%find the model in the mixture model with the highest mixture proportion
%     ipi_mean = obj.mu(ipi_index);
%     ipi_var = obj.Sigma(ipi_index);
%     ipi_SD = sqrt(ipi_var);
%     obj = {};
%     obj{1} = original_ipi.fit;
    
    ipi =struct('u',[],'S',[],'d',[],'t',[],'fit',{});
end

