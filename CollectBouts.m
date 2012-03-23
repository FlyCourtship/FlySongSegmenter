function [file_names Bouts] = CollectBouts(folder)
%USAGE  [file_names Bouts] = CollectBouts(folder)

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

Bouts = cell(1,file_num);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
            %get plot data and limits
            load(path_file,'bouts');
            file_names{i} = file;
            Bouts{i} = bouts.x;
            
    end
end

Bouts(cellfun('isempty',Bouts))=[];
file_names(cellfun('isempty',file_names))=[];

Bouts=cat(1,Bouts{:});









