function FlySongSegmenterWAV(wav_file,channel_num,song_range,params_path)

%Perform FlySongSegmenter on multiple wav files in a folder
%e.g. FlySongSegmenterWAV('/misc/public/Troy/',3,[1 1000000],'./params.m');
%processes the first million tics
%

[poolavail,isOpen] = check_open_pool;

fprintf(['Reading daq file header info.\n']);
song_wavinfo = audioinfo(wav_file);
nchannels_song = song_wavinfo.NumChannels;
try
  hyg = load([wav_file(1:end-4) '.hyg']);
catch
  hyg = [];
end

if(~isempty(channel_num) && ((sum(channel_num<1)>0) || (sum(channel_num>nchannels_song)>0)))
  warning('channel_num out of range');
end

%make directory for output
sep = filesep;
[pathstr, name, ext] = fileparts(wav_file); 
new_dir = [pathstr sep name '_out'];
mkdir(new_dir);

%grab song and noise from each channel
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range)
    song = audioread(wav_file,song_range);
else
    song = audioread(wav_file);
end

if(isempty(channel_num))  yy=1:nchannels_song;  else  yy=channel_num;  end
for y = yy
    outfile  = [new_dir sep 'PS_' name '_ch' num2str(y) '.mat'];
    if(exist(outfile,'file') == 0)  %if file exists, skip

    %run FlySongSegmenter on selected channel
    %fprintf('Processing song.\n')
    [Data, Sines, Pulses, Params] = ...
        FlySongSegmenter(song(:,y),[],params_path,song_wavinfo.SampleRate);

    %save data
    Data.wavinfo = song_wavinfo;
    Data.hygrometer = hyg;
    save(outfile, 'Data','Sines','Pulses','Params','-v7.3');

    %clear workspace
    clear song Data Sines Pulses Params

    else
        fprintf(['File %s exists. Skipping.\n'], outfile);
    end
end

check_close_pool(poolavail,isOpen);
