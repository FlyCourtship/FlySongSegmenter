function [b fb]=my_polyspectrum(a,fa,h)

% a and fa are 1-sided FFT as from my_pwelch
% integers in h specify which harmonics to multiply

k=nan(size(a,1),length(h));
b=nan(size(a));
for(i=1:size(a,2))
  for(j=1:length(h))
    k(:,j)=a(:,max(1,round(1+(i-1)*abs(h(j)/h(end)))));
    if(h(j)<0)  k(:,j)=conj(k(:,j));  end
  end
  b(:,i)=prod(k,2);
end

fb=fa./abs(h(end));
