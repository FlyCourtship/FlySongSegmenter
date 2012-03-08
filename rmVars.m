function rmVars(folder,variables)
%variables is a cell array of variables to be removed
%e.g.
%{'pulse' 'bout' 'bouts'}

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

numvars = numel(variables);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder sep file];
    TG = strcmp(ext,'.mat');
    if TG == 1
        fprintf([root '\n']);
        
        W = who('-file',path_file);
        varstruc =struct;
        load(path_file);
        for ii = 1:numel(W)
            varstruc.(W{ii}) = eval(W{ii});
        end
        for i = 1:numvars
            if isfield(varstruc,variables{i})
                varstruc =rmfield(varstruc, variables{i});
            end
        end
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
    end
end

