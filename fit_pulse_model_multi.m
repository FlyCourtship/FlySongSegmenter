function fit_pulse_model_multi(folder,pulseInfo_name)
%USAGE fit_pulse_model_multi(folder,pulseInfo_name)
%pulseInfo_name can take 'pulseInfo', 'pulseInfo2', etc.

pI_name = char(pulseInfo_name);

[poolavail,isOpen] = check_open_pool;

%sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    
    if TG == 1
        
        pIData = load(path_file,pI_name);
        pI_data = pIData.(pI_name);
        [pulse_model,Lik_pulse] = fit_pulse_model(pI_data.x);
        
        
        W = who('-file',path_file);
        varstruc =struct;
        load(path_file);
    
        for ii = 1:numel(W)
            varstruc.(W{ii}) = eval(W{ii});
        end
        varstruc.pulse_model = pulse_model;
        varstruc.Lik_pulse = Lik_pulse;
        
        varstruc.pulse_model.variables.pulseInfo_ver = pI_name;
        varstruc.pulse_model.variables.date = date;
        varstruc.pulse_model.variables.time = clock;
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
       
    end
end

check_close_pool(poolavail,isOpen)


