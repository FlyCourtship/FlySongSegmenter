function [maxFFTFreq] = sine_song_analyze(winnowed_sine)

Fs = 22050;
nfft = 100000;

for i = 1:size(winnowed_sine.clips);

    ym = winnowed_sine.clips{i};
    r = length(ym);
    sec = r/10000;
    wnd = 22050*sec;
    z = resample(ym,22050,10000);
    
    M=[];
    [Sn,F] = spectrogram(z,wnd,[],nfft,Fs);
    a = find(F>80 & F<250);
    freq2 = F(a);
    voltage = abs(Sn(a,:));
    M = mean(voltage,2);

    [C,I] = max(M); %I = index of max of of the signal between 80-250Hz
    maxFFTFreq(i) = freq2(I); %the frequency with this index
end