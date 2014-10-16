function FlySongSegmentFolderOfFoldersWAV(folder_of_folder_of_wav_files,song_range,params_path)

%Perform FlySongSegmenter on multiple wav files in a folder
%e.g. FlySongSegmenterWAV('/misc/public/Troy/',[1 1000000],'./params.m');
%processes the first million tics 
%


%make directory for output
if ~strcmp(folder_of_folder_of_wav_files(end),'/')
    folder_of_folder_of_wav_files = [folder_of_folder_of_wav_files filesep];
end
folder = dir(folder_of_folder_of_wav_files);
for y = 1:numel(folder)
    if folder(y).isdir
        if ~strncmp(folder(y).name,'.',1)
            FlySongSegmenterWAV([folder_of_folder_of_wav_files folder(y).name],[],song_range,params_path);
        end
    end
end
