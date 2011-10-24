function Process_daq_Song(song_daq_file,song_range)

%old - when require noise file
%function Process_daq_Song(song_daq_file,song_range)


song_daqinfo = daqread(song_daq_file,'info');
%noise_daqinfo = daqread(noise_daq_file,'info');

% if nargin == 3
%     song_range = song_range;
% elseif nargin == 4
%     song_range = song_range;
%     noise_range = noise_range;
% end

%Produce batch process file, with daq 

nchannels_song = length(song_daqinfo.ObjInfo.Channel);
%nchannels_noise = length(noise_daqinfo.ObjInfo.Channel);

%make directory for output
sep = filesep;
[pathstr, name, ext] = fileparts(song_daq_file); 
new_dir = [pathstr name '_out'];
mkdir(new_dir);

% if nchannels_song ~= nchannels_noise
%     fprintf('Number of channels of song and noise daqs do not agree.\n');
%     return
% else
for y = 1:nchannels_song
    outfile = [new_dir sep 'PS_ch' num2str(y) '.mat'];
    file_exist = exist(outfile,'file');
    if file_exist == 0;%if file exists, skip
        %grab song and noise from each channel
        fprintf(['Grabbing song and noise from daq file channel %s.\n'], num2str(y))
        if nargin ==2
            song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
            %noise = daqread(noise_daq_file,'Channels',y);
            %elseif nargin ==4
            %   song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
            %  noise = daqread(noise_daq_file,'Channels',y,'Samples',noise_range);
        else
            song = daqread(song_daq_file,'Channels',y);
            %noise = daqread(noise_daq_file,'Channels',y);
        end
        %grab sample rate from daq and replace value in params, with
        %warning
        fs = song_daqinfo.ObjInfo.SampleRate;
        fprintf('Using sample rate from daq file\n')
        
        %run Process_Song on selected channel
        fprintf('Processing song.\n')
        [ssf,noise_ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo] = Process_Song(song);
        %save data
        
        save(outfile, 'ssf','noise_ssf','winnowed_sine','pps',...
            'pulseInfo2','pulseInfo','pcndInfo')
        %clear workspace
        clear song noise ssf noise_ssf winnowed_sine pps pulseInfo2 pulseInfo pcndInfo
    else
        fprintf(['File %s exists. Skipping.\n'], outfile)
    end
end
%end