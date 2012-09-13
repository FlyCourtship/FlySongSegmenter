%input ssf and expected min and max for sine song fundamental frequency 

% output is inRangeEvents giving all events deemed legitimate sine song
% and lengthTable which gives start, finish, and lengths of all sine song

% user enters min and max value for fundamental frequency

% events should be a 2 column matrix (ie, if lengthfinder is run immediately
% after sinesongfinder, events will be ans.events)

function sinesong = lengthfinder4(ssf, min, max,sine_range_percent,discard_less_n_steps)

%other potential user defined variables -- These have been moved to
%Process_Song

%search within ± this percent to determine whether consecutive events are
%continuous sine
%sine_range_percent = 0.2;
%discard_less_n_steps = 3;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create matrix of all legitimate sine events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sinemin=min;
sinemax=max;
allevents=ssf.events;%column 1 = time in sec, column 2 is freq in Hz
stepsize=ssf.dS;
windowsize=ssf.dT;
fs=ssf.fs;
data = ssf.d;
inRangeEvents=[];

for n=1:numel(ssf.events(:,1))
    
    %Check if each value within bounds, or within bounds of second harmonic.
    %Either triggers saving value
    if allevents(n,2)>=sinemin && allevents(n,2)<=sinemax || allevents(n,2)>=2*sinemin && allevents(n,2)<=2*sinemax
        inRangeEvents=cat(1,inRangeEvents,allevents(n,:)); 
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if no data in range of sine song, then exit gracefully, saving sinesong=0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if numel(inRangeEvents) == 0
    fprintf('No sine song in this clip.\n')
	sinesong.num_events = 0; %return sinesong as 0 (false)
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
   

% %%eliminate singleton time points - this assumes that sine must be >
% %%stepsize
% 
% RunsEvents = [];
% NumEvents = numel(UnqInRangeEvents(:,1));
% %first deal with first time point
% if UnqInRangeEvents(2,1) - UnqInRangeEvents(1,1) < 2*stepsize %if only one time step
%     RunsEvents(1,:) = UnqInRangeEvents(1,:);
% end
% %then deal with all but last time point
% y = 2;
% for x  = 2:NumEvents-1   
%     if UnqInRangeEvents(x+1,1) - UnqInRangeEvents(x,1) < 2*stepsize || UnqInRangeEvents(x,1) - UnqInRangeEvents(x-1,1) < 2*stepsize %if neighboring at least one next step
%         RunsEvents(y,:) = UnqInRangeEvents(x,:);
%         y = y + 1;
%     end
% end
% %then deal with last time point
% if UnqInRangeEvents(NumEvents,1) - UnqInRangeEvents(NumEvents-1,1) < 2*stepsize %if only one time step
%     RunsEvents(y,:) = UnqInRangeEvents(NumEvents,:);
% end


%sinesong = RunsEvents;

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
sine_start(NumBouts) = RunsEvents(1,1)-windowsize/2;
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
        
        sine_stop(NumBouts) = RunsEvents(x,1)+windowsize/2;
        NumBouts = NumBouts + 1;
        sine_start(NumBouts) = RunsEvents(x+1,1)-windowsize/2;
        
    end
    
end


%plug in last value as last stop
sine_stop(NumBouts) = RunsEvents(NumEvents,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%winnow to bouts > discard_less_n_steps 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for x = NumBouts:-1:1
    if sine_stop(x) - sine_start(x) <= discard_less_n_steps * stepsize
        sine_start(x)=[];
        sine_stop(x)=[];
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%winnow to eliminate runs that contain no values in fundamental frequency range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NumEvents = numel(sine_start);
for x = NumEvents:-1:1
    %get events for each run
    events_in_run = find(RunsEvents(:,1)>=sine_start(x) & RunsEvents(:,1)<=sine_stop(x));
    %if no data in fundamental frequency range eliminate this run
    if isempty(find(RunsEvents(events_in_run,2)>=sinemin & RunsEvents(events_in_run,2) <=sinemax, 1));
        sine_start(x)=[];
        sine_stop(x)=[];
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now use start and stop times to calculate other parameters of interest
%and to grab clips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rdcdNumBouts = numel(sine_start);
NumBouts=rdcdNumBouts;

length=zeros(NumBouts,1);
MeanFundFreq=zeros(NumBouts,1);
MedianFundFreq=zeros(NumBouts,1);
sine_clips = cell(NumBouts,1);
statevents =[];


length = sine_stop - sine_start;

for x = 1:NumBouts;
    sine_clips{x} = data((int32(sine_start(x)*fs)):int32(sine_stop(x)*fs));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Produce output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sinesong.num_events = numel(sine_start);
sinesong.start = sine_start';
sinesong.stop = sine_stop';
sinesong.length = length;
sinesong.clips = sine_clips;
 

end
