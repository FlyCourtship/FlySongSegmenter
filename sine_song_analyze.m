function [maxFFTFreq] = sine_song_analyze(winnowed_sine)

Fs = 22050;
nfft = 100000;

for i = 1:size(winnowed_sine.clips);

    ym = winnowed_sine.clips{i};
    r = length(ym);
    sec = r/10000;
    wnd = round(22050*sec);
    z = resample(ym,22050,10000);
    
    voltage=[];
    [Sn,F] = spectrogram(z,wnd,[],nfft,Fs);
    a = find(F>80 & F<250);
    freq2 = F(a);
    voltage = abs(Sn(a,:));

    [C,I] = max(voltage); %I = index of max of of the signal between 80-250Hz
    maxFFTFreq(i) = freq2(I); %the frequency with this index
end