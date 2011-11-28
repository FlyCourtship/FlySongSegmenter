function gamparamEsts = gamma_fit(x)
%Usage gamparamEsts = gamma_fit(x)

%fit a two component gamma mixture model
%code estimates starting parameters by first estimating 2 component norm
%mix model, then using u±S to get range of xlow and xhigh, then estimate
%gamma parameters from each of these

%fit norm mixture model to data x
options = statset('MaxIter',500);
obj=gmdistribution.fit(x',2,'options',options);
normu1 = obj.mu(1);
normu2 = obj.mu(2);
normS1 = obj.Sigma(1);
normS2 = obj.Sigma(2);

%grab estimated low and high distributions of the data
if normu1 < normu2
    low = x(x<(normu1+normS1) & x>(normu1-normS1));
    high = x(x<(normu2+normS2) & x>(normu2-normS2));
else
    low = x(x<(normu2+normS2) & x>(normu2-normS2));
    high = x(x<(normu1+normS1) & x>(normu1-normS1));
end

%TO DO - Test 1-n component gamma models
% compare likelihood of different mixture models
%how precisely do I do this?


pdf_gammixture = @(x,p,A1,A2,B1,B2) p*gampdf(x,A1,B1) + (1-p)*gampdf(x,A2,B2);
oneStart = gamfit(low);
twoStart = gamfit(high);
pStart = numel(low)/(numel(low) +numel(high));
start = [pStart oneStart(1) twoStart(1) oneStart(2) twoStart(2)];
lb = [0 0 0 0 0];
ub = [1 Inf Inf Inf Inf];
options = statset('MaxIter',1000, 'MaxFunEvals',1200);
paramEsts = mle(x, 'pdf',pdf_gammixture, 'start',start, 'lower',lb, 'upper',ub,'options',options);




gamparamEsts.p = paramEsts(1); %paramEsts returns p,A1,A2,B1,B2
gamparamEsts.A = paramEsts([2 3]); %bundle alphas
gamparamEsts.B = paramEsts([4 5]); %bundle betas
