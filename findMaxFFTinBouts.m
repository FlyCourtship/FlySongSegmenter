function bout_maxFFT = findMaxFFTinBouts(bouts,maxFFT)

time = cell(numel(bouts.Start),1);
freq = cell(numel(bouts.Start),1);
for i = 1:numel(bouts.Start)
    boutTimes = bouts.Start(i):bouts.Stop(i);
    tf = ismember(maxFFT.timeAll,boutTimes);
    time{i} = maxFFT.timeAll(tf);
    freq{i} = maxFFT.freqAll(tf);
end

bout_maxFFT.time =time;
bout_maxFFT.freq =freq;