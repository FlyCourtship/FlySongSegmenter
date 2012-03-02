function bouts = collectSongBouts(data,winnowed_sine,culled_ipi)

%make array length of recording
%make this a 0/1 index for absence/presence of song
song = zeros(size(data.d,1),1);


%grab times of sine song, set to 1

sineStart = round(winnowed_sine.start);
sineStop = round(winnowed_sine.stop);

for i = 1:numel(sineStart)
    song(sineStart(i):sineStop(i)) = 1;
end

%grab times of pulse song, set to 1

ipiStart = round(culled_ipi.t);
ipiDur = round(culled_ipi.d);

for i = 1:numel(ipiStart)
    song(ipiStart(i):(ipiStart(i)+ipiDur(i))) = 1;
end

%check remaining intervals for fit to ipi distribution

%grab times of remaining stretches of 0s in song


%%%%TO DO
remainingIntervals = 










alpha = .01;
prob = cdf(culled_ipi.fit,remainingIntervals);
alpha = alpha / 2;
gapFill = remainingIntervals(prob < 1-alpha);
song(gapFill) = 1;

%call bout start and start times and runs of 1s

%%%%TO DO













%make cell array of bouts
x = cell(numel(Start),1);
for i = 1:x
   x{i} = data.d(Start):data.d(Stop);
end


bouts.Start = Start;
bouts.Stop = Stop;
bouts.x = x;