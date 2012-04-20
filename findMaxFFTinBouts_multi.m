function findMaxFFTinBouts_multi(folder)

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
        bouts = varstruc.bouts;
        
        bout_maxFFT = findMaxFFTinBouts(bouts,maxFFT);
        
        varstruc.bout_maxFFT = bout_maxFFT;
        
        varstruc.bout_maxFFT.variables.date = date;
        varstruc.bout_maxFFT.variables.time = clock;
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
    end
end

