function clips = GetClips(start_times, stop_times, varargin)
%function clips = GetClips(start_times, stop_times, file, channel)
%function clips = GetClips(start_times, stop_times, data)
%
%e.g.
%Pulses.IPICull.x = GetClips(Pulses.IPICull.w0, Pulses.IPICull.w1, '../data/augusto.daq', 3);
%Sines.LengthCull.clips = GetClips(Sines.LengthCull.start, Sines.LengthCull.stop, Data.d);

if(nargin==4)
  file=varargin{1};
  channel=varargin{2};
  if(~strcmp(file(end-3:end),'.daq'))
    error('only .daq files supported currently');
  end
  data = daqread(file,'Channels',channel);
elseif(nargin==3)
  data = varargin{1};
else
  error('invalid input args');
end

clips=cell(1,length(start_times));
for c=1:length(start_times)
  clips{c} = data(start_times(c):stop_times(c));
end
