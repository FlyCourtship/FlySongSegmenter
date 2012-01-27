function Process_daq_Song(song_daq_file,song_range)

%old - when require noise file
%function Process_daq_Song(song_daq_file,song_range)
poolavail = exist('matlabpool','file');%check if toolbox is available
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
        matlabpool(getenv('NUMBER_OF_PROCESSORS'))
        isOpen = -1;%now know pool was opened in this scripts (no negative pools from matlabpool('size'))
    end
end

song_daqinfo = daqread(song_daq_file,'info');
%noise_daqinfo = daqread(noise_daq_file,'info');

if nargin == 1
    range = 0;
else
    range=1;
end

%Produce batch process file, with daq 

nchannels_song = length(song_daqinfo.ObjInfo.Channel);
%nchannels_noise = length(noise_daqinfo.ObjInfo.Channel);
%grab sample rate from daq and replace value in params, with
%warning       
 
fs = song_daqinfo.ObjInfo.SampleRate;

%make directory for output
sep = filesep;
[pathstr, name, ext] = fileparts(song_daq_file); 
new_dir = [pathstr sep name '_out'];
mkdir(new_dir);


for y = 1:nchannels_song
    outfile  = [new_dir sep 'PS_' name '_ch' num2str(y) '.mat'];
    file_exist = exist(outfile,'file');
    if file_exist == 0;%if file exists, skip
        %grab song and noise from each channel
        fprintf(['Grabbing song from daq file channel %s.\n'], num2str(y))
        if range == 1
            song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
        else
            song = daqread(song_daq_file,'Channels',y);
        end
 
        %run Process_Song on selected channel
        fprintf('Processing song.\n')
        [data, winnowed_sine, pulseInfo2, pulseInfo] = Process_Song(song);
        %save data
        
        save(outfile, 'data','winnowed_sine','pulseInfo2','pulseInfo','-v7.3')
        %clear workspace
        clear song data winnowed_sine pulseInfo2 pulseInfo
    else
        fprintf(['File %s exists. Skipping.\n'], outfile)
    end
end
if isOpen == -1%if pool opened in this script, then close
    if poolavail~=0
        matlabpool close force local
    end
end