function Process_multi_daq_Song(folder,song_range)

%function Process_multi_daq_Song(folder_containing_multiple_daqs,song_range)
%This function allows you to analyze mutiple daqs in a folder and gives you
%outputs in separate folders.

poolavail = exist('matlabpool','file');%check if toolbox is available
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
        matlabpool(getenv('NUMBER_OF_PROCESSORS'))
        isOpen = -1;%now know pool was opened in this scripts (no negative pools from matlabpool('size'))
    end
end

sep = filesep;
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

if isOpen == -1%if pool opened in this script, then close
    if poolavail~=0
        matlabpool close force local
    end
end

