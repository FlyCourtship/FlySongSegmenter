%%winnow sine to eliminate overlap with pulse song
%%There are two general categories to winnow
%%1 - sine that immediately precedes or follows pulses and overlaps 1 pulse
%%2 - sine that falls between and overlaps pulses
%%Case 1 can be winnowed simply by finding the set of sine song that does
%%not overlap pulses
%%Case 2 is partially solved by the same winnowing, but may leave a small
%%window of sine between two neighboring pulses. This requires defining a
%%threshold for the maximum distance between two pulses (max_pulse_pause) 
%%between which sine should be removed.

function winnowed_sine = winnow_sine2(sine,pulseInfo2,ssf,max_pulse_pause,min,max)

%USER DEFINED VARIABLE -- HAS BEEN MOVED TO Process_Song
% max_pulse_pause = 0.200; %max_pulse_pause in seconds
% min = 100;
% max = 200;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Winnow 1: Remove sine that overlaps pulse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get # sig digits for rounding signal data
%Add one significant digit to ensure capture data with sample frequencies
%that are not in units of 10
% sigdig = abs(order(1/ssf.fs))+1;

% %convert to integer
% %this is a hack until all the code is converted to integer
% sineStart = round(sine.start .* ssf.fs);
% sineStop = round(sine.stop .* ssf.fs);
% sineTime = round(ssf.t .* ssf.fs);
% ssfeventTimes = round(ssf.events(:,1) .* ssf.fs);

sineStart = sine.start ;
sineStop = sine.stop;
sineTime = ssf.t;
ssfeventTimes = ssf.events(:,1);


%get all time points of sine song
% sample_sine=[];
all_sine=cell(numel(sine.num_events),1);
for i = 1:sine.num_events
    all_sine{i} = (sineStart(i):1:sineStop(i));
end
all_sine = cell2mat(all_sine);
%get all time points of pulse (w1 - w0)
% sample_pulse=[];
all_pulses=cell(numel(pulseInfo2.w0),1);
for i = 1:numel(pulseInfo2.w0)
    all_pulses{i} = (pulseInfo2.w0(i):1:pulseInfo2.w1(i))';
end
all_pulses = cell2mat(all_pulses);

%round data to # sig digits of sampling rate
% all_sine = round(all_sine * 10^sigdig)./(10^sigdig);
% all_pulses = round(all_pulses * 10^sigdig)./(10^sigdig);


%remove sine that overlaps pulse
winnowed_sine_1 = setdiff(all_sine,all_pulses);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Winnow 2: remove sine song falling between two pulses that are less than
%%max_pulse_pause apart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get all pulse_pauses
pulse_pauses=cell(numel(pulseInfo2.w0-1),1);
for i = 1:numel(pulseInfo2.w0)-1
        if pulseInfo2.w0(i+1)/ssf.fs-pulseInfo2.w1(i)/ssf.fs < max_pulse_pause
            pulse_pauses{i} = (pulseInfo2.w1(i):1:pulseInfo2.w0(i+1))';
        end
end
pulse_pauses(cellfun('isempty',pulse_pauses))=[];
pulse_pauses = cell2mat(pulse_pauses);

%remove sine that falls within a pulse pause
winnowed_sine_2 = setdiff(winnowed_sine_1,pulse_pauses);

%winnowed_sine_2 = winnowed_sine_1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%call contiguous sequence to get start and stop times
%sine_start and sine_stop now represent winnowed sine values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[sine_start,sine_stop] = contiguous_sequence(winnowed_sine_2);

%then recalc all variables

%length = sine_stop - sine_start;

NumBouts = numel(sine_start);

sine_clips = cell(NumBouts,1);

for i = 1:NumBouts
    sine_clips{i} = ssf.d(sine_start(i):sine_stop(i));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%For each clip, get original F-test events that overlap with times between 
%sine_start and sine_stop
%times are in column 1 of ssf.events
%frequencies are in column 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%MeanFundFreq=zeros(NumBouts,1);
%MedianFundFreq=zeros(NumBouts,1);
sine_bout_events=cell(NumBouts,1);
sine_bout_power = cell(NumBouts,1);
sine_bout_events_times = cell(NumBouts,1);
for i = 1:NumBouts
    sine_bout = sine_start(i):1:sine_stop(i);
        
    %get indices of values in events that are also found in sine_bout
    event_times = ismember(ssfeventTimes,sine_bout');

    values = ssf.events(event_times,2);
    times = ssfeventTimes(event_times);
    times= times(values>=min & values <= max);
    values = values(values>=min & values <=max);%take only values that fall between min and max
    
    sine_bout_events{i} = values;
    sine_bout_events_times{i} = times;
    temp_power = zeros(numel(values),1);
    for j = 1:numel(values)
        temp_power(j) = ssf.A(ssf.f == values(j),sineTime == times(j));
    end
    sine_bout_power{i} = temp_power;
end
% sine_bout_events(cellfun('isempty',sine_bout_events))=[];
% sine_bout_power(cellfun('isempty',sine_bout_power))=[];
    
    
%winnowed_sine.num_events = NumBouts;
winnowed_sine.start = sine_start';
winnowed_sine.stop = sine_stop';
%winnowed_sine.length = length;
%winnowed_sine.MeanFundFreq = MeanFundFreq';
%winnowed_sine.MedianFundFreq=MedianFundFreq';
winnowed_sine.clips = sine_clips;
winnowed_sine.events = sine_bout_events;
winnowed_sine.eventTimes = sine_bout_events_times;
winnowed_sine.power = sine_bout_power;
winnowed_sine.powerMat = cell2mat(sine_bout_power);

%winnowed_sine.all_sine = all_sine;
%winnowed_sine.winnowed_sine1 = winnowed_sine_1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function to identify contiguous segments of data with a defined sampling
%freq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [start,stop] = contiguous_sequence(array)
start = [];
stop=[];
if numel(array) > 0
    start(1) = array(1);
    N_runs = 1;
    for x = 1:numel(array)-1%for all but last sample
        if array(x+1) == array(x) + 1%if next sample is step_size away, then part of same contiguous sequence
            
        else%record stop and next start
            stop(N_runs) = array(x);
            N_runs = N_runs+1;
            start(N_runs) = array(x+1);
        end
    end
    %for last sample
    stop(N_runs)=array(x+1);
end
