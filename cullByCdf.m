function culled_ipi = cullByCdf(ipi,Components,alpha)
%USAGE culled_ipi = cullByCdf(ipi,Components,alpha);
%Note that alpha is the two tailed alpha
%If you want to eliminite all data with p<.01, then enter .005

%Rescale mixing proportions
den = sum(ipi.fit.PComponents(Components));
mixprops = ipi.fit.PComponents(Components) / den;
mu = ipi.fit.mu(Components);
std = sqrt(ipi.fit.Sigma(Components));
obj = gmdistribution(mu,std,mixprops);

prob = cdf(obj,ipi.d');

culled_d = ipi.d(prob >alpha & prob < 1-alpha);
culled_t = ipi.t(prob >alpha & prob < 1-alpha);

culled_ipi.u = mu;
culled_ipi.S = std;
culled_ipi.d = culled_d;
culled_ipi.t = culled_t;
culled_ipi.fit = obj;