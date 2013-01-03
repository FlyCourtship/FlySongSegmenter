function FlySongSegmenterDAQ(song_daq_file,channel_num,song_range,params_path)

%Perform FlySongSegmenter on multiple channels from a single daq file
%e.g. FlySongSegmenterDAQ('/misc/public/Troy/20120302081902.daq',3,[1 1000000],'./params.m');
%processes the first million tics of channel #3
%
%e.g. FlySongSegmenterDAQ('20120302081902.daq',[],[],'./params.m');
%processes all of the tics of all of the channels.
%w/o a full path the file must be in the current directory.

[poolavail,isOpen] = check_open_pool;

fprintf(['Reading daq file header info.\n']);
song_daqinfo = daqread(song_daq_file,'info');
nchannels_song = length(song_daqinfo.ObjInfo.Channel);
try
  hyg = load([song_daq_file(1:end-4) '.hyg']);
catch
  hyg = [];
end

if(~isempty(channel_num) && ((sum(channel_num<1)>0) || (sum(channel_num>nchannels_song)>0)))
  warning('channel_num out of range');
end

%make directory for output
sep = filesep;
[pathstr, name, ext] = fileparts(song_daq_file); 
new_dir = [pathstr sep name '_out'];
mkdir(new_dir);


if(isempty(channel_num))  yy=1:nchannels_song;  else  yy=channel_num;  end
for y = yy
    outfile  = [new_dir sep 'PS_' name '_ch' num2str(y) '.mat'];
    if(exist(outfile,'file') == 0)  %if file exists, skip
        %grab song and noise from each channel
        fprintf(['Grabbing song from daq file channel %s.\n'], num2str(y));
        if ~isempty(song_range)
            song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
        else
            song = daqread(song_daq_file,'Channels',y);
        end
 
        %run FlySongSegmenter on selected channel
        %fprintf('Processing song.\n')
        [Data, Sines, Pulses, Params] = ...
            FlySongSegmenter(song,[],params_path,song_daqinfo.ObjInfo.SampleRate);
        
        %save data
        data.daqinfo = song_daqinfo;
        data.hygrometer = hyg;
        save(outfile, 'Data','Sines','Pulses','Params','-v7.3');

        %clear workspace
        clear song Data Sines Pulses Params
    else
        fprintf(['File %s exists. Skipping.\n'], outfile);
    end
end

check_close_pool(poolavail,isOpen);
