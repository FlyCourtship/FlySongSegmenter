function fit_pulse_model_multi(folder)

%function fit_pulse_model_multi(folder_containing_multiple_daqs,song_range)
%This function allows you to analyze mutiple daqs in a folder and gives you
%outputs in separate folders.

[poolavail,isOpen] = check_open_pool;

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder sep file];
    TG = strcmp(ext,'.mat');
    
    
    if TG == 1
        load(path_file);
        [pulse_model,Lik_pulse] = fit_pulse_model(pulseInfo.x);
        out_file = [folder sep root '_pm.mat'];
        save(out_file,'pulse_model','Lik_pulse','-mat')
    end
end

check_close_pool(poolavail,isOpen)
