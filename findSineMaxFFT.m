function sMFFT = findSineMaxFFT(winnowed_sine,Fs)

nfft = 100000;

NumSine = numel(winnowed_sine.clips);
maxFFTFreq = cell(NumSine,1);
maxFFTFreqTime = cell(NumSine,1);
% [poolavail,isOpen] = check_open_pool;
parfor i = 1:NumSine 
    ym = winnowed_sine.clips{i};
    boutStart = winnowed_sine.start(i);
    boutStop = winnowed_sine.stop(i);
    r = length(ym);
    sec = r/10000;
    if r>1
        if sec < 0.1
            wnd = round(Fs*sec);
            z = resample(ym,Fs,10000);
            [Sn,F,T] = spectrogram(z,wnd,[],nfft,Fs);
            a = find(F>70 & F<300);
            freq2 = F(a);
            voltage = abs(Sn(a,:));
            
            [~,I] = max(voltage); %I = index of max of the signal between 50-300Hz
            maxFFTFreq{i} = freq2(I); %the frequency with this index
            maxFFTFreqTime{i} = boutStart+(T(1) * Fs);
            
        elseif sec > 0.1
            wnd = round(0.1*Fs);
            z = resample(ym,Fs,10000);
            [Sn,F,T] = spectrogram(z,wnd,[],nfft,Fs);
            a = find(F>70 & F<300);
            freq2 = F(a);
            voltage = abs(Sn(a,:));
            
            [~,I] = max(voltage); %I = index of max of the signal between 50-300Hz
            maxFFTFreq{i} = freq2(I); %the frequency with this index
            maxFFTFreqTime{i} = boutStart+(T(1) * Fs):(T(1) * Fs):boutStop - (T(1) * Fs);
        end
    end
end

sMFFT.freq = maxFFTFreq;
sMFFT.time = maxFFTFreqTime;
sMFFT.freqAll = cell2mat(maxFFTFreq);
sMFFT.timeAll = cell2mat(maxFFTFreqTime');


