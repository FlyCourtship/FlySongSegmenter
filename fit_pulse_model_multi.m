function fit_pulse_model_multi(folder,pulseInfo_ver)
%
%pulseInfo_ver can take '1', '2', 'pcnd'

%Indicate here which version of pulseInfo to use
if nargin <2
    pulseInfo_ver = '1';
end

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
        if pulseInfo_ver == '1'
            [pulse_model,Lik_pulse] = fit_pulse_model(pulseInfo.x);
        elseif pulseInfo_ver == '2'
            [pulse_model,Lik_pulse] = fit_pulse_model(pulseInfo2.x);
        elseif pulseInfo_ver == 'pcnd'
            [pulse_model,Lik_pulse] = fit_pulse_model(pcndInfo.x);
        end
        out_file = [folder sep root '_pm.mat'];
        save(out_file,'pulse_model','Lik_pulse','-mat')
    end
end

check_close_pool(poolavail,isOpen)
