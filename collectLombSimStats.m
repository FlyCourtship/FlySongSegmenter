% culled_ipi = ipiStatsLomb.culled_ipi;

%%%Now loop through all mat files in folder and collect lomb_sim_results in

% lsr.filename{ } = filename
% lsr.results{ } = lomb_sim_results;

function lsr = collectLombSimStats(folder)

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end

%USAGE lsr = collectLombSimStats(folder)
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

file_names = cell(1,file_num);
lomb_sim_results = cell(1,file_num);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
        fprintf([root '\n']);
        load(path_file,'data','ipiStatsLomb');
        lomb_sim_results{i} = lomb_sim(data,ipiStatsLomb.culled_ipi);
        file_names{i} = file;
    end
end

lsr.filename = file_names;
lsr.results = lomb_sim_results;



function lomb_sim_results = lomb_sim(data,ipi)
%ippi =  ipiStatsLomb.culled_ipi


fs = 1e4;
SNR  = .1:.1:2;
d = cell(numel(SNR),1);
P = d;
f = d;
alpha = d;
best_alpha = zeros(numel(SNR),1);
best_P = best_alpha;
for i=1:numel(SNR)
    [simData,Pow,freq,sign] = sine_sim(data.d,ipi,fs,SNR(i));
    d{i} = simData;
    P{i} = Pow;
    f{i} = freq;
    alpha{i} = sign;
    freq_range_of_interest = sign(freq > .017 & freq < .019);
    if numel(freq_range_of_interest) > 1
        best_alpha(i) = min(freq_range_of_interest);
        best_P(i) = max(Pow(freq > .017 & freq < .019));        
    end
end

lomb_sim_results.d = d;
lomb_sim_results.P = P;
lomb_sim_results.f = f;
lomb_sim_results.alpha = alpha;
lomb_sim_results.best_alpha = best_alpha;
lomb_sim_results.best_P = best_P;



function [simData,P,f,alpha] = sine_sim(d,ipi,fs,SNR)
t = 1:size(d); %10 minutes
f = 1/(55*fs);%freq = 1/period
% fs = 1e4;
A = 0.002; %amplitude ~2msec
% A = 1;
x = A *sin(2*pi*f*t);
 
% plot(t,x)

% culled_ipi = ipi;
cx = x(ipi.t);
ct = ipi.t;
% plot(ct,cx,'.-')
%  
% lomb(cx,ct./fs,1);
 
%Now try adding variance to cx
% SNR = .4;
% rmsrnd = sqrt(mean(randn(size(x,2),1).^2));
% rmsx = sqrt(mean(x.^2));

stdx = std(ipi.d./fs);
 
% noise = (1/.7088)*(rmsx/SNR) .* randn(size(cx,2),1);
noised = (1/.7088)*(stdx/SNR) .* randn(size(cx,2),1);

% cy = cx+noise';
cyd = cx+noised';

% plot(ct,cy,'.-')
% lomb(cy,ct./fs,1);

% plot(ct,cyd,'.-')
[P,f,alpha] = lomb(cyd,ct./fs);%,1);
%don't plot
% [P,f,alpha] = lomb(cyd,ct./fs,1);
simData.t = ct;
simData.x = cyd;

%%%%%%%%%%%%%%%%%%%
%check rmsq vs rmsrnd
% t = 1:size(data.d); %10 minutes
% f = 1/55e4;%freq = 1/period
% A = 1;
% x = A *sin(2*pi*f*t);
% rmsx = sqrt(mean(x.^2))
% rmsrnd = sqrt(mean(randn(size(x,2),1).^2))
