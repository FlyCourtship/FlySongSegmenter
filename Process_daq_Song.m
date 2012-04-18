function Process_daq_Song(song_daq_file,channel_num,song_range,params_path)

%old - when require noise file
%function Process_daq_Song(song_daq_file,song_range)
[poolavail,isOpen] = check_open_pool;

song_daqinfo = daqread(song_daq_file,'info');
%noise_daqinfo = daqread(noise_daq_file,'info');

%if nargin == 1
%    range = 0;
%else
%    range=1;
%end

%Produce batch process file, with daq 

nchannels_song = length(song_daqinfo.ObjInfo.Channel);
if(~isempty(channel_num) && ((channel_num<1) || (channel_num>nchannels_song)))
  warning('channel_num out of range');
end
%nchannels_noise = length(noise_daqinfo.ObjInfo.Channel);
%grab sample rate from daq and replace value in params, with
%warning       
 
fs = song_daqinfo.ObjInfo.SampleRate;

%make directory for output
sep = filesep;
[pathstr, name, ext] = fileparts(song_daq_file); 
new_dir = [pathstr sep name '_out'];
mkdir(new_dir);


if(isempty(channel_num))  yy=1:nchannels_song;  else  yy=channel_num;  end
for y = yy
    outfile  = [new_dir sep 'PS_' name '_ch' num2str(y) '.mat'];
    file_exist = exist(outfile,'file');
    if file_exist == 0;%if file exists, skip
        %grab song and noise from each channel
        
        fprintf(['Grabbing song from daq file channel %s.\n'], num2str(y))
        if ~isempty(song_range)
            song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
        else
            song = daqread(song_daq_file,'Channels',y);
        end
 
        %run Process_Song on selected channel
        fprintf('Processing song.\n')
        [data, winnowed_sine, pulseInfo, pulseInfo2, pcndInfo] = Process_Song(song,[],params_path);
        %save data
        
        save(outfile, 'data','winnowed_sine', 'pcndInfo','pulseInfo2','pulseInfo','-v7.3')
        %clear workspace
        clear song data winnowed_sine pulseInfo2 pulseInfo
    else
        fprintf(['File %s exists. Skipping.\n'], outfile)
    end
end
check_close_pool(poolavail,isOpen);
