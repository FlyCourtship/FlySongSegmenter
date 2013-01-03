%Batch Fly Song Analysis

function FlySongReSegmenter(out_folder)

% ReSegment fly song, e.g. using new params
%
% out_file: full path to daq_name_out_folder 
%

[poolavail,isOpen] = check_open_pool;

%check if _out folder exists
folder = out_folder;
if ~isdir(folder)
    error('myApp:argChk','Analysis stopped.\nFolder with previously segmented song does not exist.');
end

%get _out folder info
dir_list = dir(folder);
file_num = numel(dir_list);

for y = 1:file_num
    
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder '/' file];
    if strcmp(ext,'.mat');

        %load data
        load(path_file,'Data')
        %Run FlySongSegmenter
        [Data, Sines, Pulses, Params] = FlySongSegmenter(Data.d,[],[]);

        %Save results back in same file
        save(path_file,'Data','Sines','Pulses','Params');
    end
end

check_close_pool(poolavail,isOpen);


function my_save(result_path,Analysis_Results)

save(result_path,'Analysis_Results','-mat');
