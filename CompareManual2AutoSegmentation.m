function [sensitivity,positive_predictive_value,F_score] = ...
    CompareManual2AutoSegmentation(xsongsegment,manual,automatic,Fs);

%function [sensitivity,positive_predictive_value,F_score] = ...
%    CompareManual2AutoSegmentation(xsongsegment,manual,automatic,Fs);
%
%[sensitivity,positive_predictive_value,F] = ...
%    CompareManual2AutoSegmentation(xsongsegment,PULSE,Pulses.ModelCull,Fs);

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

manual(:,2) = round(manual(:,2).*Fs/1000);
manual(:,3) = round(manual(:,3).*Fs/1000);

for i=1:length(manual(:,2)); %for each pulse
    a = manual(i,2);
    b = manual(i,3);
    %pulse_length = b-a+1;
    vector_manual(a:b) = ones;
end

%Now create a vector of 0.1s and ones for pulseInfo2 start and stop times

leng = length(xsongsegment);

vector_comp = zeros(1,leng);
vector_comp = vector_comp + 0.1;

for i=1:numel(automatic.w0); %for each pulse
    a = automatic.w0(i);
    b = automatic.w1(i);
    %pulse_length = b-a+1;
    vector_comp(a:b) = ones;
end

%Guassian filter:
Fs=10000;
effwidth = 20; 
efftk = -3*effwidth:3*effwidth ; 
effkernel = (exp(-(efftk/effwidth).^2/2)/(effwidth*sqrt(2*pi)));
halfWidth=(numel(efftk)/2);

vector_manual_pulse_guass = conv(vector_manual,effkernel); %convolve with the guassian kernel
VMPG=vector_manual_pulse_guass(halfWidth:end-halfWidth);
vector_auto_pulse_guass = conv(vector_comp,effkernel);
VAPG = vector_auto_pulse_guass(halfWidth:end-halfWidth);

%for each vector, get rid of the first 80 and last 80 points, and jitter VMPG (by 45pts) relative to the other vectors 
%(the jitter is done because we don't want any peaks in VMPG to PERFECTLY overlap with the peaks in the other vectors) - the code here is looking for interesections between the two vectors:
VMPG(1:125)=[];
VMPG(end-34:end)=[];
VAPG(1:80)=[];
VAPG(end-79:end)=[];

%vector for the timepoints
ll=length(VMPG);
t=1:ll;

%now use curveintersect.m to find the points where the vectors intersect:
[VAPGi,VAPGv] = curveintersect(t,VMPG,t,VAPG); %i=indices, v=values

%the intersections should be greater than 0.1 (see above, all of the vectors have 0.1 as their min value) - the length of this vector provides the value of
%"trues_found" - that is the pulses that were found by each algorithm that
%are ALSO in "trues"
Ca=find(VAPGv>0.1);

%for deugging: verify that the correct peaks were found:
figure; plot(t,VMPG,'k',t,VAPG,'b',VAPGi,VAPGv,'ro')
hold on
plot(VAPGi(Ca),0.12,'.m');

%to get the number of pulses from each original vector, use findpeaks:
VMPG_peaks = findpeaks(VMPG,'minpeakheight',0.1);
VAPG_peaks = findpeaks(VAPG,'minpeakheight',0.1);

%Now calculate false positive (a.k.a. false alarm) and false negative (a.k.a. miss) rates:
%sensitivity(sen) = trues_found/trues
%positive predictive value(ppv) = trues_found/found
%F=2*sen*ppv/(sen+ppv)

sensitivity = length(Ca)/length(VAPG_peaks);

positive_predictive_value = length(Ca)/length(VAPG_peaks);

F_score = (2*sensitivity*positive_predictive_value)/(sensitivity+positive_predictive_value);
