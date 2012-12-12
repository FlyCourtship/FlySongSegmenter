function clips=GetClips(file,channel,start_times,stop_times)

%Pulses.IPICull.clips=GetClips('../data/augusto.daq',3,Pulses.IPICull.w0,Pulses.IPICull.w1);
%Sines.LengthCull.clips=GetClips('../data/augusto.daq',3,Sines.LengthCull.start,Sines.LengthCull.stop);

if(~strcmp(file(end-3:end),'.daq'))
  error('only .daq files supported currently');
end

data = daqread(file,'Channels',channel);

clips=cell(1,length(start_times));
for c=1:length(start_times)
  clips{c} = data(start_times(c):stop_times(c));
end
