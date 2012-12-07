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

%% culling by length now done here instead of SineSegmenter

function [CulledFromPulses CulledByLength] = ...
    WinnowSine(data, SinesMergedInTimeHarmonics, Pulses, SinesFromMultiTaper,...
    Fs, dS, max_pulse_pause, sine_low_freq, sine_high_freq, discard_less_n_steps)

%USER DEFINED VARIABLE -- HAS BEEN MOVED TO FlySongSegmenter
% max_pulse_pause = 0.200; %max_pulse_pause in seconds
% min = 100;
% max = 200;

if(SinesMergedInTimeHarmonics.num_events==0)
  CulledFromPulses={};
  CulledByLength={};
  return;
end

stepsize=round(dS * Fs);
%data = SinesFromMultiTaper.d;

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

sineStart = SinesMergedInTimeHarmonics.start ;
sineStop = SinesMergedInTimeHarmonics.stop;
sineTime = SinesFromMultiTaper.t;
ssfeventTimes = SinesFromMultiTaper.events(:,1);


%get all time points of sine song
% sample_sine=[];
all_sine=cell(numel(SinesMergedInTimeHarmonics.num_events),1);
for i = 1:SinesMergedInTimeHarmonics.num_events
    all_sine{i} = (sineStart(i):1:sineStop(i));
end
all_sine = cell2mat(all_sine);
%get all time points of pulse (w1 - w0)
% sample_pulse=[];
all_pulses=cell(numel(Pulses.w0),1);
for i = 1:numel(Pulses.w0)
    all_pulses{i} = (Pulses.w0(i):1:Pulses.w1(i))';
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
pulse_pauses=cell(numel(Pulses.w0-1),1);
for i = 1:numel(Pulses.w0)-1
        if Pulses.w0(i+1)/Fs-Pulses.w1(i)/Fs < max_pulse_pause
            pulse_pauses{i} = (Pulses.w1(i):1:Pulses.w0(i+1))';
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
    sine_clips{i} = data(sine_start(i):sine_stop(i));
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
    event_idx = ismember(ssfeventTimes,sine_bout');
    values = SinesFromMultiTaper.events(event_idx,2);
    times = ssfeventTimes(event_idx);
    times= times(values>=sine_low_freq & values <= sine_high_freq);
    values = values(values>=sine_low_freq & values <=sine_high_freq);%take only values that fall between min and max
    
    sine_bout_events{i} = values;
    sine_bout_events_times{i} = times;
    temp_power = zeros(numel(values),1);
    for j = 1:numel(values)
        temp_power(j) = SinesFromMultiTaper.A(SinesFromMultiTaper.f == values(j),sineTime == times(j));
    end
    sine_bout_power{i} = temp_power;
end
% sine_bout_events(cellfun('isempty',sine_bout_events))=[];
% sine_bout_power(cellfun('isempty',sine_bout_power))=[];
    
    
%CulledFromPulses.num_events = NumBouts;
CulledFromPulses.start = sine_start';
CulledFromPulses.stop = sine_stop';
%CulledFromPulses.length = length;
%CulledFromPulses.MeanFundFreq = MeanFundFreq';
%CulledFromPulses.MedianFundFreq=MedianFundFreq';
CulledFromPulses.clips = sine_clips;
CulledFromPulses.events = sine_bout_events;
CulledFromPulses.eventTimes = sine_bout_events_times;
CulledFromPulses.power = sine_bout_power;
CulledFromPulses.powerMat = cell2mat(sine_bout_power);

%CulledFromPulses.all_sine = all_sine;
%CulledFromPulses.winnowed_sine1 = winnowed_sine_1;

if(isempty(CulledFromPulses.start))
  CulledByLength={};
  return;
end

 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%winnow to bouts > discard_less_n_steps 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for x = NumBouts:-1:1
    if sine_stop(x) - sine_start(x) <= discard_less_n_steps * stepsize
        sine_start(x)=[];
        sine_stop(x)=[];
    end
end


%  BJA---  already done in SineSegmenter, no?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%winnow to eliminate runs that contain no values in fundamental frequency range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NumEvents = numel(sine_start);
%for x = NumEvents:-1:1
%    %get events for each run
%    events_in_run = find(RunsEvents(:,1)>=sine_start(x) & RunsEvents(:,1)<=sine_stop(x));
%    %if no data in fundamental frequency range eliminate this run
%    if isempty(find(RunsEvents(events_in_run,2)>=sine_low_freq & RunsEvents(events_in_run,2) <=sine_high_freq, 1));
%        sine_start(x)=[];
%        sine_stop(x)=[];
%    end
%end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now use start and stop times to calculate other parameters of interest
%and to grab clips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rdcdNumBouts = numel(sine_start);
NumBouts=rdcdNumBouts;
sine_clips = cell(NumBouts,1);
length = sine_stop - sine_start;

for x = 1:NumBouts;
    sine_clips{x} = data(sine_start(x):sine_stop(x));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Produce output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CulledByLength.num_events = numel(sine_start);
CulledByLength.start = sine_start';
CulledByLength.stop = sine_stop';
CulledByLength.length = length;
CulledByLength.clips = sine_clips;
 




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
