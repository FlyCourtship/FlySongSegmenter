function [bouts] = findSongBouts(data,winnowed_sine,ipiBouts,Pauses,threshold)

% threshold = 1e4;%this should be set depending on distribution of pauses

%ipi best if ipiStatsLomb.culled_ipi

%make array length of recording
%make this a 0/1 index for absence/presence of songennd
song = zeros(size(data.d,1),1);
% sinesong = zeros(size(data.d,1),1);
% pulsesong = zeros(size(data.d,1),1);
%grab times of sine song, set to 1


sineStart = round(winnowed_sine.start);
sineStop = round(winnowed_sine.stop);

for i = 1:numel(sineStart)
%     sinesong(sineStart(i):sineStop(i)) = 1;
    song(sineStart(i):sineStop(i)) = 1;
end

%grab times of pulse song, set to 1

ipiStart = cell2mat(ipiBouts.t);
ipiDur = cell2mat(ipiBouts.d);

for i = 1:numel(ipiStart)
    song(ipiStart(i):(ipiStart(i)+ipiDur(i))) = 1;
%     pulsesong(ipiStart(i):(ipiStart(i)+ipiDur(i))) = 1;
end


%Remove pauses if < threshold
PauseDelta = Pauses.PauseDelta;
PauseTime = Pauses.Time;
shortPausesIdx = find(PauseDelta < threshold);
maskStart = PauseTime(shortPausesIdx)+1;
maskStop = maskStart+PauseDelta(shortPausesIdx);
for i = 1:numel(maskStart)
    song(maskStart(i):maskStop(i)) =1;
end

%call bout start and stop times 

x = diff(song);
% y = find(x);
Starts = find(x==1);
Stops = find(x==-1);

Start = Starts + 1;
Stop = Stops;

if song(1) == 1 %then have song from the very beginning
    Start = [1;Start];
end
if song(end) == 1 %then have song at very end
    Stop = [Stop;numel(song)];
end


%pad bouts by IPI on either side
max_IPI = max(ipiDur);
Start = Start - max_IPI;
Stop = Stop + max_IPI;


%if indixes run off beginning or end, then trim back
Start(Start < 1) = 1;
Stop(Stop > numel(song)) = numel(song);

%make cell array of bouts
bout_events	 = cell(numel(Start),1);
for i = 1:numel(bout_events)
   bout_events{i} = data.d(Start(i):Stop(i));
end


bouts.Start = Start;
bouts.Stop = Stop;
bouts.x = bout_events;

