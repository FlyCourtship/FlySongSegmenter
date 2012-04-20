%function [H t]=brown_puckette(x,N,Fs,nharm,guess)
%
%given a time series x sampled at Fs, extract the
%frequencies H at times t of nharm
%harmonics using an initial fundamental frequency
%estimate of guess and overlapped chunks of size N.

function [H t]=brown_puckette(x,N,Fs,nharm,guess)

R=3;   % radius in which to look for maxima.
M1=2;  % max must be this ratio higher,
M2=2;  %   this many pts away

l=1;
m=1;
f=(0:N/2)*Fs/N;
while((l+N-1)<=length(x))
  X=fft(x(l:(l+N-1)));
  Xw=fft(x(l:(l+N-1)).*hamming(N)');
  t(m)=(l+N/2)/Fs;
  [foo k0]=min(abs(f-guess));
  for(j=1:nharm)
    if((round(j*k0-R)<1) || (round(j*k0+R)>length(X)/2))
      %[foo k0]=min(abs(f-guess));
      if(j>1)  H(j,m)=nan;  continue;
      else     H(:,m)=nan;  break;
      end
    end
    [foo,k]=max(abs(Xw(round(j*k0-R):round(j*k0+R))));
    k=k+round(j*k0-R)-1;
    %if((k<R) || (abs(Xw(k))/abs(Xw(k-M2))<M1) || (abs(Xw(k))/abs(Xw(k+M2))<M1))
    if(((k-M2)<1) || ((k+M2)>length(X)/2) || ...
        (abs(Xw(k))/abs(Xw(k-M2))<M1) || (abs(Xw(k))/abs(Xw(k+M2))<M1))
      if(j>1)  H(j,m)=nan;  continue;
      else     H(:,m)=nan;  break;
      end
    end
    Xh0=0.5*(X(k)-0.5*X(k+1)-0.5*X(k-1));
    Xh1=0.5*exp(sqrt(-1)*2*pi*(k-1)/N)*...
        (X(k) - 0.5*exp(sqrt(-1)*2*pi/N)*X(k+1) - 0.5*exp(-sqrt(-1)*2*pi/N)*X(k-1));
    phi0=atan2(imag(Xh0),real(Xh0));
    phi1=atan2(imag(Xh1),real(Xh1));
    if((phi1-phi0)<0)  phi1=phi1+2*pi;  end
    H(j,m)=(phi1-phi0)*Fs/(2*pi);
    if(j==1)  k0=H(j,m)*N/Fs;  end
  end
  if(isnan(H(1,m)))
    break;
  else
    guess=H(1,m);
  end
  l=l+N/2;  m=m+1;
end
