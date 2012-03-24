function Process_multi_daq_Song(folder,song_range)

%function Process_multi_daq_Song(folder_containing_multiple_daqs,song_range)
%This function allows you to analyze mutiple daqs in a folder and gives you
%outputs in separate folders.

%[poolavail,isOpen] = check_open_pool;

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,~,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.daq');
    
    
    if TG == 1
        if nargin ==2
            Process_daq_Song(path_file,song_range);
        else
            Process_daq_Song(path_file);
        end
    end
end

%check_close_pool(poolavail,isOpen);

