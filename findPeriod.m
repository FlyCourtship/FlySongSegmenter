function period = findPeriod(pulse_model)

pm = pulse_model;
pm = smooth(pulse_model);%perform gentle smoothing to eliminate ridges at peaks and troughs
%get max and min values
pmmax = regionalmax(pm);
pmmin = regionalmax(-pm);
max = pm(pmmax);
maxidx = find(pmmax==1);
min = pm(pmmin);
minidx = find(pmmin==1);
%get abs vales and indexes
a(:,1) = abs(max);
a(:,2) = maxidx;
i(:,1) = abs(min);
i(:,2) = minidx;
%collect all max and min values
all = cat(1,a,i);
all = sortrows(all,-1);

%find top three hits, these are the peak and two troughs of pulse model
peaks = zeros(3,2);
for i = 1:3
    peaks(i,1) = pm(all(i,2));
    peaks(i,2) = all(i,2);
end
%determine which are pos (1) and which are neg (0)
pos = zeros(3,1);
for i =1:3
    pos(i) = isreal(sqrt(peaks(i,1)));
end

if sum(pos) == 1; %if one positive, take two negs
    troughs = peaks(pos ==0,:);
else %or else take two poss
    troughs = peaks(pos ==1,:);
end
troughIdx = troughs(:,2);
period = abs(diff(troughIdx));


