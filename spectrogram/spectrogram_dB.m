%%
%================================
%for fly song, perform spectrogram (window = 200ms)

song = small_song; %ideal filtered 100-900Hz
song = song./55; %gain of 55 on Brownlee amp
l = length(song); 
N = [];
N1 = [];
N2 = [];
S1 = [];
F1 = [];
T1 = [];
Fs = 10000;
nwnd = 200; %20ms
nfft = 10000;
nwnd = window(@gausswin,nwnd);
noverlap = 190;
[S1,F1,T1] = spectrogram(song,nwnd,noverlap,nfft,Fs);

%make N1, which is the same as S1, but with values in dB SPL
for i = 1:length(T1);
    N(:,i) = 2*abs(S1(:,i)); %take the 2*abs of each column of S1
    %N(:,i) = smooth(N(:,i),201);
    N1(:,i)= 94 + 20*log10(N(:,i)./test_max_20ms); %convert to dB SPL
    N2(1,i)=max(N1(:,i)); %store the max dB SPL value for each column
end

figure(1);
plot(T1,N2,'r');

%plot the spectrogram:
figure(2);
%dbThresh = 30;
%N1(N1<30) = 30;
hndl = surf(T1,F1,N1,'EdgeColor','none');
axis xy; axis tight;
colormap(jet);
view(0,90);
ylabel('Hz');
xlabel('seconds');
ylim([0 1000]);