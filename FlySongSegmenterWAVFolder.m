function FlySongSegmenterWAVFolder(folder_of_wav_files,song_range,params_path)

%Perform FlySongSegmenter on multiple wav files in a folder
%e.g. FlySongSegmenterWAV('/misc/public/Troy/',[1 1000000],'./params.m');
%processes the first million tics 
%


%make directory for output
if ~strcmp(folder_of_wav_files(end),'/')
    folder_of_wav_files = [folder_of_wav_files '/'];
end
folder = dir(folder_of_wav_files);
for y = 1:numel(folder)
    [~, ~, ext] = fileparts(folder(y).name);
    if strcmp(ext,'.wav')
        file_in_question = [folder_of_wav_files folder(y).name];
        FlySongSegmenterWAV(file_in_question,song_range,params_path)
    end
end
