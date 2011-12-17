function  [IPI, meanIPI, stdIPI, IPIs_within_stdev,train_times,IPI_train,train_length,pulses_per_train, meanIPI_train, pulsefreq_train, meanpulsefreq_train, mean_IPI, mean_freq,N,NN, train] = analyze(pulseInfo2,xsong,winnowed_sine);

Fs=10000;

B=[];
B = pulseInfo2.wc; %times for pulse peaks

%analyze IPIs================================
IPI = (diff(B)./10); %all IPIs in ms (this vector is one shorter than pulseInfo2.wc)
index = find(IPI < 100); %ignore IPIs > 100ms (these don't occur in pulse trains likely)

bb = pulseInfo2.wc(index+1); %these are the pulse peak times for the IPIs we want to keep - for this peak, IPI is the difference between it and the peak before it

% figure(1); plot(ssf.d.*10,'k');
% hold on;
% plot(bb,IPI(index),'.b'); %plot the IPIs

meanIPI = mean(IPI(index)); %mean IPI
stdIPI = std(IPI(index)); %standard deviation

%look at IPIs within one stdev from the mean=============
A=IPI(index);
index2 = find(A>meanIPI-stdIPI); %want to ignore those IPIs that are less than one st dev from the mean
cc = bb(index2); %times for these IPIs
%hold on; plot(cc, A(index2),'.r'); 
IPIs_within_stdev = (A(index2));

h=figure(11); hist(IPIs_within_stdev,50); title('IPI histogram');
saveas(h,'IPI_hist.fig'); 

lambda = poissfit(round(IPIs_within_stdev));
xval = min(round(IPIs_within_stdev)):1:max(round(IPIs_within_stdev));
Y = poisspdf(xval,lambda); 
%Y=Y./max(Y);

h=figure(2); plot(xval, Y,'-r'); title('IPI Poisson dist');
saveas(h,'IPI_poisson_dist.fig'); 

%find pulse trains==============================
a=find(IPI>meanIPI+2*stdIPI); %these larger IPIs must be the starts of pulse trains
AA = [];
last=[];
for ll = 1:length(a);
    r = a(ll); %r is the index
    AA(ll,1) = pulseInfo2.wc(r+1); %this is the index for the pulse at the start of the pulse train
    IPI_new = IPI(r+1:length(IPI));
    ab = find(IPI_new > meanIPI+stdIPI); %this will find all IPIs from IPI(r) on that are greater than the meanIPI + stdIPI
    if isempty(ab)==1;
        break
    end
    last = ab(1) + r; %this is the index of IPI vector that signals the end of the pulse train (so this same index in pulseInfo2.wc would be the last pulse in the train)
    AA(ll,2) = pulseInfo2.wc(last);
end
%now have a matrix AA, which contains a list of all of the start times (first column) and all end times (second column) of pulse trains.

%plot to make sure:
% figure(6); plot(ssf.d.*10,'k'); %plot the signal
% hold on;
% plot(AA(:,1),ones,'.r'); 
% plot(AA(:,2),ones,'.b');

%only take a look at those pulse trains that contain > 3 pulses:
train_times=[];
R=[];
n=1;
for i=1:size(AA,1);
    start = AA(i,1);
    stop = AA(i,2);
    index = find(pulseInfo2.wc>start & pulseInfo2.wc<stop);
    R(i) = length(index);
    if length(index)>1;
        train_times(n,:) = AA(i,:);
        n=n+1;  
    end
end
%BB has the start and stop times of all "lengthy" pulse trains

%plot to make sure:
% figure(7); plot(ssf.d.*10,'k'); %plot the signal
% hold on;
% plot(BB(:,1),ones,'.r'); 
% plot(BB(:,2),ones,'.b');

%now look at trends within a train=============================
IPI_train={};
pulsefreq_train={};
for i = 1:size(train_times,1);
   a =  find(pulseInfo2.wc == train_times(i,1)); %a is the index of pulseInfo2.wc equal to the pulse train start time
   b = find(pulseInfo2.wc == train_times(i,2)); %b is the index of pulseInfo2.wc equal to the pulse train stop time
   IPI_train{i} = IPI(a:b-1);
   train_length(i) = sum(IPI_train{i});
   pulses_per_train(i) = length(IPI_train{i})+1; 
   meanIPI_train(i) = mean(IPI(a:b-1));
   stdIPI_train(i) = std(IPI(a:b-1));
   pulsefreq_train{i} = pulseInfo2.fcmx(a:b);
   meanpulsefreq_train(i) = mean(pulseInfo2.fcmx(a:b));
end

%plot the start times of pulse trains versus the meanIPI or mean pulsefreq within that train
h=figure(3); errorbar(train_times(:,1)./Fs,meanIPI_train,stdIPI_train,'.-k'); title('mean IPI within a train versus train start time');
saveas(h,'meanIPI_pulsetrainstart.fig'); 
h=figure(4); plot(train_times(:,1)./Fs,meanpulsefreq_train,'.-r');  title('mean pulse frequency within a train versus train start time');
saveas(h,'meanpulsefreq_pulsetrainstart.fig');
h=figure(5); plot(train_times(:,1)./Fs,pulses_per_train,'.-g'); title('number of pulses per train versus train start time');
saveas(h,'pulsespertrain_pulsetrainstart.fig');

%plot the IPI trends:
yf=[];
rsquare=[];
n=1;
for i=1:size(IPI_train,2);
aa=length(IPI_train{i});
if aa>5; %if there are at least 6 pulses in the train
vect = (1:aa);
[cfun,cfit,output] = fit(vect', IPI_train{i}', 'exp1'); %exp1: Y = a*exp(b*x)
rsquare(i) = cfit.adjrsquare;
const = cfun.b;
xf = linspace(1,60,60);
    if cfit.adjrsquare>0.45;
    train(n) = i;
    yf(n,:) = exp(const*xf);
    n=n+1;
    end
end
end

h=figure(6); for i=1:size(yf,1);
hold on; plot(yf(i,:));
end
ylim([0 5]); title('exponential fits of IPIs within a train');
saveas(h,'expfits_IPI_train.fig'); 

%means for each position in the train=========================
mean_IPI = NaN(size(IPI_train,2),60);
mean_freq = NaN(size(IPI_train,2),60);
for i=1:size(IPI_train,2);
    mean_IPI(i,1:length(IPI_train{i})) = IPI_train{i};
    mean_freq(i,1:length(pulsefreq_train{i})) = pulsefreq_train{i};
end
mean_IPI_plot = mean_IPI';
t = 1:1:60;
h = figure(66); plot(t,mean_IPI_plot);  title('IPIs for each pulse train');
saveas(h,'IPI_each_train.fig');
ave_IPI = nanmean(mean_IPI,1);
std_IPI = nanstd(mean_IPI,1);

h=figure(7); boxplot(mean_IPI); title('IPI stats within a train');
saveas(h,'IPI_boxplot.fig'); 
h=figure(8); boxplot(mean_freq); title('pulsefreq stats within a train');
saveas(h,'pulsefreq_boxplot.fig'); 


%statistics of pulse trains follwed by sine?===========================
N = zeros(1,length(xsong)); %N is the location and length of all sines
NN = zeros(1,length(xsong)); %NN is the location and length of all pulse trains containing > 3 pulses

for i=1:length(winnowed_sine.start);
    N(round(winnowed_sine.start(i))*10000:round(winnowed_sine.stop(i))*10000) = 1;
end

for i=1:length(train_times);
    NN(train_times(i,1):train_times(i,2)) = 1;
end

h=figure(9); plot(N,'.b'); hold on; plot(NN,'.r'); ylim([0.9 1.1]); title('sine(blue) and pulse(red) locations'); saveas(h,'sine_pulse_locations.fig');

%look at the distribution of the number of pulses per train for pulse
%trains within 70ms of sine song and those that are not.  

m=1;
r=1;
train_start_times_alone=[];
train_times_index_alone=[];
train_start_times_near_sine_song=[];
train_times_index_near_sine_song=[];
  
for n=1:length(train_times);
    A = train_times(n,1); %A is the start time of this pulse train
    A1 = train_times(n,2); %A1 is the stop time of this pulse train

    AA = find(N); %find the places in xsong that have sine song

    AAA = find(A-1000 < AA & AA < A); AAAA = find(A1 < AA & AA < A1+1000); 
    
    tf=isempty(AAA); tf2=isempty(AAAA);
    
    if tf==1 && tf2==1; %no sine song 100ms before or 100ms after this pulse train
        train_start_times_alone(m) = A;
        train_times_index_alone(m) = n;
        m=m+1;
    else %if there is sine song either before or after
        train_start_times_near_sine_song(r) = A;
        train_times_index_near_sine_song(r) = n;
        r=r+1;
    end
end



%stats:
% ind=[];
% ind2=[];
% ind=find(NN); %the location of all pulse trains 
% ind2 = find(N); %the location of all sine songs
% figure; plot(ind,1,'r'); hold on; plot(ind2,1,'b');


%y = a + Bcos(2pi/x)(t-x2)

% h=figure(3); plot(train_times(:,1)./Fs,meanIPI_train,'.-k'); title('mean IPI within a train versus train start time');
% saveas(h,'meanIPI_pulsetrainstart.fig'); 

% load count.dat
% c3 = count(:,3); % Data at intersection 3 
% tdata = (1:24)'; 
% X = [ones(size(tdata)) cos((2*pi/x)*(tdata-x2))];
% s_coeffs = X\c3;
% 
% figure
% plot(c3,'o-')
% hold on
% tfit = (1:0.01:24)';
% yfit = [ones(size(tfit)) cos((2*pi/x)*(tfit-x2))]*s_coeffs; 
% plot(tfit,yfit,'r-','LineWidth',2)
% legend('Data','Sinusoidal Fit','Location','NW')



