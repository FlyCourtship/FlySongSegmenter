function convert_winnowed_sine_values(folder)

%this utility converts winnowed_sine.start and stop times back to original
%samples, rather than seconds. In future, all code should work on samples

fs = 1e4;

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    if TG == 1
            fprintf([path_file '\n']);
            
            W = who('-file',path_file);
            varstruc =struct;
            load(path_file);
            if exist('winnowed_sine','var')
                start = round(winnowed_sine.start .* fs);
                stop = round(winnowed_sine.stop .* fs);
                
                for ii = 1:numel(W)
                    varstruc.(W{ii}) = eval(W{ii});
                end
                varstruc.winnowed_sine.start = start;
                varstruc.winnowed_sine.stop = stop;
                
                save(path_file,'-struct','varstruc','-mat')%save all variables in original file
            end
            
    end
end