function MergedInTimeHarmonics = SineSegmenter(data, SinesFromMultiTaper, Fs, dT, dS, sine_low_freq, sine_high_freq, sine_range_percent)
%input ssf and expected min and max for sine song fundamental frequency 

% output is inRangeEvents giving all events deemed legitimate sine song
% and lengthTable which gives start, finish, and lengths of all sine song

% user enters min and max value for fundamental frequency

% events should be a 2 column matrix (ie, if lengthfinder is run immediately
% after MultiTaperFTest, events will be ans.events)

%other potential user defined variables -- These have been moved to
%FlySongSegmenter

%search within ± this percent to determine whether consecutive events are
%continuous sine
%sine_range_percent = 0.2;
%discard_less_n_steps = 3;

% culling by length now done in WinnowSine


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create matrix of all legitimate sine events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allevents=SinesFromMultiTaper.events;%column 1 = time in sec, column 2 is freq in Hz
stepsize=round(dS * Fs);
windowsize_half=round(dT * Fs/2);
%data = SinesFromMultiTaper.d;
inRangeEvents=[];

for n=1:numel(SinesFromMultiTaper.events(:,1))
    
    %Check if each value within bounds, or within bounds of second harmonic.
    %Either triggers saving value
    if allevents(n,2)>=sine_low_freq && allevents(n,2)<=sine_high_freq || allevents(n,2)>=2*sine_low_freq && allevents(n,2)<=2*sine_high_freq
        inRangeEvents=cat(1,inRangeEvents,allevents(n,:)); 
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if no data in range of sine song, then exit gracefully, saving sinesong=0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if numel(inRangeEvents) == 0
    fprintf('No sine song in this clip.\n')
	MergedInTimeHarmonics.num_events = 0; %return sinesong as 0 (false)
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% reduce array to unique time points (i.e. eliminate redundant harmonics)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
UnqInRangeEvents = [];
UnqInRangeEvents(1,:) = inRangeEvents(1,:);
row = 2;
for x  = 2:numel(inRangeEvents(:,1))
    if inRangeEvents(x,1) ~= inRangeEvents(x-1,1) %if not same time as previous
        UnqInRangeEvents(row,:) = inRangeEvents(x,:); %save
        row = row + 1;
    end
end
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%create chains of sine song
%%look for whether event in time t+1 is within a % boundary of the t event
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sine_start = [];
sine_stop = [];
start = 0;
RunsEvents = UnqInRangeEvents;

NumEvents = numel(RunsEvents(:,1));

%First, get start and stop values for runs
NumBouts = 1;
sine_start(NumBouts) = RunsEvents(1,1)-windowsize_half;
if sine_start(NumBouts) < 1
    sine_start(NumBouts) = 1;
end

for x  = 1:(NumEvents-1)
    
    
    %get values for two time points
    first = RunsEvents(x,2);
    next = RunsEvents(x+1,2);
    low_next = next - next*sine_range_percent;
    high_next = next + next*sine_range_percent;
    %Determine range that counts as possible second and third harmonics of
    %sine song
    second_harmonic = first*2;
    next_second_harmonic = next*2;
    low_next_second_harmonic = next_second_harmonic - next_second_harmonic *sine_range_percent;
    high_next_second_harmonic = next_second_harmonic + next_second_harmonic *sine_range_percent;
    third_harmonic = first*3;
    next_third_harmonic = next*3;
    low_next_third_harmonic = next_third_harmonic - next_third_harmonic *sine_range_percent;
    high_next_third_harmonic = next_third_harmonic + next_third_harmonic *sine_range_percent;
    
    %conditional arguments used to winnow to fundamental and harmonics
    
    matchesSecondOrThird = low_next<first&&first<high_next||low_next_second_harmonic<first*2&&first*2<high_next_second_harmonic||low_next_third_harmonic<first*3&&first*3<high_next_third_harmonic;%if event is first harmonic
    matchesFirstOrThird = low_next<first&&first<high_next||low_next<first*0.5&&first*0.5<high_next||low_next_third_harmonic<first*1.5&&first*1.5<high_next_third_harmonic;%if event is second harmonic
    matchesFirstOrSecond = low_next<first&&first<high_next||low_next<first/3&&first/3<high_next||low_next_second_harmonic<first*2/3&&first*2/3<high_next_second_harmonic;%if event is third harmonic
    matchesAny = matchesSecondOrThird||matchesFirstOrThird||matchesFirstOrSecond;
    
    %test to see if consecutive time points are adjacent and if they are
    %harmonics of each other
    if RunsEvents(x+1,1) - RunsEvents(x,1) < 2*stepsize && matchesAny%as long as bout continues
    else%reach stop, maybe store data
        
        sine_stop(NumBouts) = RunsEvents(x,1)+windowsize_half;
        NumBouts = NumBouts + 1;
        sine_start(NumBouts) = RunsEvents(x+1,1)-windowsize_half;
        
    end
    
end


%plug in last value as last stop
sine_stop(NumBouts) = RunsEvents(NumEvents,1);
if sine_stop(NumBouts) > numel(data)
    sine_stop(NumBouts) = numel(data);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now use start and stop times to calculate other parameters of interest
%and to grab clips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rdcdNumBouts = numel(sine_start);
NumBouts=rdcdNumBouts;
sine_clips = cell(NumBouts,1);
len = sine_stop - sine_start;

for x = 1:NumBouts;
    sine_clips{x} = data(sine_start(x):sine_stop(x));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Produce output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(isempty(sine_start))
  MergedInTimeHarmonics = [];
else
  %MergedInTimeHarmonics.num_events = numel(sine_start);
  MergedInTimeHarmonics.start = sine_start';
  MergedInTimeHarmonics.stop = sine_stop';
  %MergedInTimeHarmonics.len = len;
  MergedInTimeHarmonics.clips = sine_clips;
end
