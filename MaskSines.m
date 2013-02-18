function sm_xsong = MaskSines(xsong,Sines)
sm_xsong = xsong;
numsines = numel(Sines.start);
if any(Sines.start)
    for i = 1:numsines
        positions_to_mask = Sines.start(i):Sines.stop(i);
        sm_xsong(positions_to_mask) = 0;
    end
end
