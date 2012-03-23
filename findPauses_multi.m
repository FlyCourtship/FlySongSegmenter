function findPauses_multi(folder)


if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);


for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    if TG == 1
        
        fprintf([root '\n']);
        W = who('-file',path_file);
        varstruc =struct;
        load(path_file);
        for ii = 1:numel(W)
            varstruc.(W{ii}) = eval(W{ii});
        end
        
        data = varstruc.data;
        winnowed_sine = varstruc.winnowed_sine;
        ipiBouts = varstruc.ipiBouts;
        
        pauses = findPauses(data,winnowed_sine,ipiBouts);
        
        varstruc.pauses = pauses;
        
        varstruc.pauses.variables.date = date;
        varstruc.pauses.variables.time = clock;
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
    end
end
