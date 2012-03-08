function fit_pulse_model_multi(folder,pulseInfo_name)
%USAGE fit_pulse_model_multi(folder,pulseInfo_name)
%pulseInfo_name can take 'pulseInfo', 'pulseInfo2', 'culled_pulseInfo',etc.
%If enter 'culled_pulseInfo', then model and Lik are saved with new name
%(with prefix 'culled_'

pI_name = char(pulseInfo_name);

[poolavail,isOpen] = check_open_pool;

if strncmp(pulseInfo_name,'culled_',7)
    culled = 1;
else
    culled = 0;
end

%sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    
    if TG == 1
        W = who('-file',path_file);
        varstruc =struct;
        load(path_file);
        
        for ii = 1:numel(W)
            varstruc.(W{ii}) = eval(W{ii});
        end
        
%         pIData = load(path_file,pI_name);
        pI_data = varstruc.(pI_name);
        [pM,Lp] = fit_pulse_model(pI_data.x);
        
        if culled == 1
            varstruc.culled_pulse_model = pM;
            varstruc.culled_Lik_pulse = Lp;
            varstruc.culled_pulse_model.variables.pulseInfo_ver = pI_name;
            varstruc.culled_pulse_model.variables.date = date;
            varstruc.culled_pulse_model.variables.time = clock;
            varstruc.culled_Lik_pulse.variables.pulseInfo_ver = pI_name;
            varstruc.culled_Lik_pulse.variables.date = date;
            varstruc.culled_Lik_pulse.variables.time = clock;
            
        elseif culled == 0
            varstruc.pulse_model = pM;
            varstruc.Lik_pulse = Lp;
            varstruc.pulse_model.variables.pulseInfo_ver = pI_name;
            varstruc.pulse_model.variables.date = date;
            varstruc.pulse_model.variables.time = clock;
            varstruc.Lik_pulse.variables.pulseInfo_ver = pI_name;
            varstruc.Lik_pulse.variables.date = date;
            varstruc.Lik_pulse.variables.time = clock;
        end
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
        
    end
end

check_close_pool(poolavail,isOpen)


