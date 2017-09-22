function FlySongSegmenterWAV(wav_file,song_range,params_path)

% Perform FlySongSegmenter on all channels in wav file
% e.g. FlySongSegmenterWAV('/misc/public/Troy/',[1 1000000],'./params.m');
% processes the first million tics
%
% 
FetchParams;
%make directory for output
new_dir = [wav_file '_out' filesep];
mkdir(new_dir);
songinfo = audioinfo(wav_file);
fprintf('wav file contains %s channels.\n', songinfo.NumChannels-Params.wav_file_nosong_channels);

fprintf('Grabbing song from wav file %s.\n', wav_file);
    if ~isempty(song_range)
        song = audioread(wav_file,song_range);
    else
        song = audioread(wav_file);
    end

start_channel = Params.wav_file_nosong_channels + 1;%start at first song channel
end_channel = songinfo.NumChannels;

for channel = start_channel:end_channel
    real_channel = channel-Params.wav_file_nosong_channels;
    fprintf('Analyzing channel %s.\n', num2str(real_channel))
    %run FlySongSegmenter on selected channel
    %fprintf('Processing song.\n')
    [Data, Sines, Pulses, Params] = ...
        FlySongSegmenter(song(:,channel),[],params_path);
    
    %save data
    [pathstr, name, ext] = fileparts(wav_file);
    
    outfile = [new_dir 'PS_' name '_channel_' num2str(real_channel) '.mat'];
    fprintf('Saving results for channel %s',num2str(real_channel));
    save(outfile, 'Data','Sines','Pulses','Params','-v7.3');
    clear Data Sines Pulses 
end
%clear workspace
clear song Params
