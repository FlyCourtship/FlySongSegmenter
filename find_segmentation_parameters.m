function [score] = find_segmentation_parameters(xsongsegment,PULSE,SINE,pulseInfo2,winnowed_sine,Fs);

%run this on xsongsegment, a small (3s or so) region of the song to be
%analyzed

%first do manual segmentation on this bit of song: the hand segmenter will output "PULSE", which has 3 columns:
%column 1 = channel; column 2 = pulse start time (in points); column 3 =
%pulse stop times (in points) and "SINE", which is similar for sine start
%and stop times

%The output of PULSE and SINE is in ms.  

%take pulse_start and pulse_stop and sine_start and sine_stop times and create a vector of ones and 0.1s -
%ones where pulses or sines are 1 and 0.1 everywhere else:

leng = length(xsongsegment);

vector_manual = zeros(1,leng);
vector_manual = vector_manual + 0.1;

PULSE(:,2) = round(PULSE(:,2).*Fs/1000);
PULSE(:,3) = round(PULSE(:,3).*Fs/1000);
SINE(:,2) = round(SINE(:,2).*Fs/1000);
SINE(:,3) = round(SINE(:,3).*Fs/1000);

for i=1:length(PULSE(:,2)); %for each pulse
    a = PULSE(i,2);
    b = PULSE(i,3);
    %pulse_length = b-a+1;
    vector_manual(a:b) = ones;
end

for i=1:length(SINE(:,2)); %for each sine
    a = SINE(i,2);
    b = SINE(i,3);
    %sine_length = b-a+1;
    vector_manual(a:b) = ones;
end

%Now create a vector of 0.1s and ones for pulseInfo2 and winnowed_sine
%start and stop times

leng = length(xsongsegment);

vector_comp = zeros(1,leng);
vector_comp = vector_comp + 0.1;
ws_start = round(winnowed_sine.start.*Fs);
ws_stop = round(winnowed_sine.stop.*Fs);

for i=1:numel(pulseInfo2.w0); %for each pulse
    a = pulseInfo2.w0(i);
    b = pulseInfo2.w1(i);
    %pulse_length = b-a+1;
    vector_comp(a:b) = ones;
end

for i=1:numel(winnowed_sine.start);
    a = ws_start(i);
    b = ws_stop(i);
    %sine_length = b-a+1;
    vector_comp(a:b) = ones;
end

%Now run cross-correlation:
x = vector_manual;
y = vector_comp;
c = xcorr(x,y,100,'coeff'); %with maxlags of 100 points
score = max(c);
figure; plot(xsongsegment,'k'); hold on; plot(vector_manual,'r'); plot(vector_comp,'g');


