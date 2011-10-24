function B = merge_runs(B, minSep, minWidth,varargin)
% B = merge_runs(B, MINSEP, MINWIDTH, {ORDER})
%
% Takes a vector B and merges non-zero blocks if they are less than
% MINSEP apart, and culls them if they are shorter than MINWIDTH.
%
% If the optional value ORDER == 0 (default), runs are merged
% before short runs are culled. Otherwise, short runs are culled 
% before runs are merged.
%

order = 0;
if (~isempty(varargin))
    if (isequal(varargin{1},1))
        order = 1;
    end
end

B = double(B>0);

if (isequal(order, 0))
    
    [runs,lengths,starts] = extract_runs(B,double(B==0));

    for i = 1:numel(runs)
        if (lengths(i)<minSep)
            B(starts(i):starts(i)+lengths(i)-1) = 1;
        end
    end

    [runs,lengths,starts] = extract_runs(B,double(B>0));

    for i = 1:numel(runs)
        if (lengths(i)<minWidth)
            B(starts(i):starts(i)+lengths(i)-1) = 0;
        end
    end

else

    [runs,lengths,starts] = extract_runs(B,double(B>0));

    for i = 1:numel(runs)
        if (lengths(i)<minWidth)
            B(starts(i):starts(i)+lengths(i)-1) = 0;
        end
    end
    
    [runs,lengths,starts] = extract_runs(B,double(B==0));

    for i = 1:numel(runs)
        if (lengths(i)<minSep)
            B(starts(i):starts(i)+lengths(i)-1) = 1;
        end
    end


end