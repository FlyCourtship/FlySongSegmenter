function [maxFFTFreq] = sine_song_analyze(winnowed_sine)

Fs = 22050;
nfft = 100000;
wnd = round(0.1*22050);
maxFFTFreq = {};

for i = 1:size(winnowed_sine.clips);

    ym = winnowed_sine.clips{i};
    r = length(ym);
    sec = r/10000;
    
    if sec < 0.1
    wnd = round(22050*sec);
    z = resample(ym,22050,10000);
    voltage=[];
    [Sn,F] = spectrogram(z,wnd,[],nfft,Fs);
    a = find(F>80 & F<250);
    freq2 = F(a);
    voltage = abs(Sn(a,:));
   
    [C,I] = max(voltage); %I = index of max of of the signal between 80-250Hz
    maxFFTFreq{i} = freq2(I); %the frequency with this index
        
    elseif sec > 0.1    
    z = resample(ym,22050,10000);
    voltage=[];
    [Sn,F] = spectrogram(z,wnd,[],nfft,Fs);
    a = find(F>80 & F<250);
    freq2 = F(a);
    voltage = abs(Sn(a,:));

    [C,I] = max(voltage); %I = index of max of of the signal between 80-250Hz
    maxFFTFreq{i} = freq2(I); %the frequency with this index
    end
end

%%

plot(data.d.*100,'k'); hold on;
for i=1:length(winnowed_sine.start);
    y = maxFFTFreq_new{i};
    ll = length(y);
    if ll==1;
        plot(winnowed_sine.start(i)*10000,y,'.');
        hold on
    else
    a=[];
    a = winnowed_sine.start(i)*10000:500:winnowed_sine.start(i)*10000+(500*length(y))-1;
    plot(a,y,'.');
    hold on
    end
end