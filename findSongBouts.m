function bouts = findSongBouts(data,winnowed_sine,ipiBouts)

%ipi best if ipiStatsLomb.culled_ipi

%make array length of recording
%make this a 0/1 index for absence/presence of songennd
song = zeros(size(data.d,1),1);
sinesong = zeros(size(data.d,1),1);
pulsesong = zeros(size(data.d,1),1);
%grab times of sine song, set to 1

sineStart = round(winnowed_sine.start);
sineStop = round(winnowed_sine.stop);

for i = 1:numel(sineStart)
    sinesong(sineStart(i):sineStop(i)) = 1;
    song(sineStart(i):sineStop(i)) = 1;
end

%grab times of pulse song, set to 1

ipiStart = cell2mat(ipiBouts.t);
ipiDur = cell2mat(ipiBouts.d);

for i = 1:numel(ipiStart)
    song(ipiStart(i):(ipiStart(i)+ipiDur(i))) = 1;
    pulsesong(ipiStart(i):(ipiStart(i)+ipiDur(i))) = 1;
end


%%%%%%
%NOT clear how to set max interval.
%Below set as max_IPI, but this seems to artifically divide bouts
%
%Get times from sine to pulse and pulse to sine
%What does this distirbution look like?
%IS there a natural way to divide this distribution?









%check remaining intervals for fit to ipi distribution

max_IPI = max(ipiDur);
x = diff(song);
y = find(x);
for i = 1:numel(y)-1
    if x(y(i)) == -1
        gap = y(i+1)-y(i);
        if gap < max_IPI
            song(y(i) + 1:y(i+1)) = 1;
        end
    end
end

% alpha = .01;
% prob = cdf(ipi.fit,remainingIntervals);
% alpha = alpha / 2;
% gapFill = remainingIntervals(prob < 1-alpha);
% song(gapFill) = 1;

%call bout start and stop times as runs of 1s

x = diff(song);
y = find(x);
Starts = find(x==1);
Stops = find(x==-1);

Start = Starts + 1;
Stop = Stops;

%pad bouts by IPI on either side
Start = Start - max_IPI;
Stop = Stop + max_IPI;

if Start(1) < 1 %then have song from the very beginning
    Start(1) = 1;
end
if Stop(end) >numel(data.d) %then have song at very end
    Stop(end) = numel(data.d);
end



%make cell array of bouts
x = cell(numel(Start),1);
for i = 1:numel(x)
   x{i} = data.d(Start(i):Stop(i));
end


bouts.Start = Start;
bouts.Stop = Stop;
bouts.x = x;

