function rho = swcorr(s1,s2)
% RHO = SWCORR(S1,S2)
%
% Performs a sliding window correlation of s1 against s2.

rho = swcorr_mx(s1,s2);

rho(rho==-2) = nan;

% We do this with a mex file now. 
%
% if (numel(s1)>numel(s2))
%     temp = s1;
%     s1 = s2;
%     s2 = temp;
% end
% 
% rho = zeros(1,numel(s2)-numel(s1)+1);
% 
% u1 = s1-mean(s1);
% u1 = u1./sqrt(sum(u1.^2));
% ns1 = numel(s1);
% for i = 1:numel(rho)
%     u2 = s2(i:i+ns1-1);
%     u2 = u2 - mean(u2);
%     u2 = u2./sqrt(sum(u2.^2));
%     
%     rho(i) = dot(u1,u2);
% end