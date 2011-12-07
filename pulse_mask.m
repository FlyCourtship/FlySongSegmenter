function pm_xsong = pulse_mask(xsong,pcndInfo)
pm_xsong = xsong;
numpulses = numel(pcndInfo.w0);
for i = 1:numpulses
    positions_to_mask = pcndInfo.w0(i):pcndInfo.w1(i);
    pm_xsong(positions_to_mask) = 0;
end