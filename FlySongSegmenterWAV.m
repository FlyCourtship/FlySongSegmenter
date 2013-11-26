function FlySongSegmenterWAV(wav_file,song_range,params_path)

%Perform FlySongSegmenter on multiple wav files in a folder
%e.g. FlySongSegmenterWAV('/misc/public/Troy/',[1 1000000],'./params.m');
%processes the first million tics
%


%make directory for output
new_dir = [wav_file '_out' filesep];
mkdir(new_dir);
fprintf('Grabbing song from wav file %s.\n', wav_file);
if ~isempty(song_range)
    song = wavread(wav_file,song_range);
else
    song = wavread(wav_file);
end

%run FlySongSegmenter on selected channel
%fprintf('Processing song.\n')
[Data, Sines, Pulses, Params] = ...
    FlySongSegmenter(song,[],params_path);

%save data
[pathstr, name, ext] = fileparts(file_in_question);
outfile = [new_dir 'PS_' name '.mat'];
save(outfile, 'Data','Sines','Pulses','Params','-v7.3');

%clear workspace
clear song Data Sines Pulses Params
