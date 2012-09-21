function pm_xsong = MaskPulses(xsong,pcndInfo)
pm_xsong = xsong;
numpulses = numel(pcndInfo.w0);
if any(pcndInfo.wc)%for some reason, pcndInfo is sometimes fed with array of 0s, even when no pulses.
    for i = 1:numpulses
        positions_to_mask = pcndInfo.w0(i):pcndInfo.w1(i);
        pm_xsong(positions_to_mask) = 0;
    end
end
