function pMFFT = findPulseMaxFFT(pulseInfo,Fs)

%minFFTPower = 0.01;
minFreq = 100;
maxFreq = 1500;
%rewrite in form
L = cellfun(@(x) numel(x),pulseInfo.x);
M = num2cell(L);
NFFT = Fs;
pFFT = cellfun(@(x,y) fft(x,NFFT)/y,pulseInfo.x,M,'UniformOutput',0);
%reduce each entry to NFFT/2+1
V = cellfun(@(x) 2*abs(x(1:NFFT/2+1)),pFFT,'UniformOutput',0);
[~,i] = cellfun(@(x) max(smooth(x(minFreq:maxFreq))),V);%exclude low and high freqs
i = i + minFreq;%add back low freq range
pMFFT.timeAll =pulseInfo.wc;
pMFFT.freqAll =i;
%pMFFT.MaxFFT = i(p>minFFTPower);
