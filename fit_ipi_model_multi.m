function fit_ipi_model_multi(folder,pulseInfo_name)
%USAGE fit_ipi_model_multi(folder,pulseInfo_ver,Lik_name,LLR_type,LLR_cutoff)
%Lik_name = e.g. 'Lik_pulse', 'culled_Lik_pulse' etc
%LLR_type = 'best', 'fh', or 'sh'
%pulseInfo_name can take 'pulseInfo', 'pulseInfo2', etc.

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end

dir_list = dir(folder);
file_num = length(dir_list);

% Lik_name = char(Lik_name);
pI_name = char(pulseInfo_name);

% if strcmp(LLR_type,'best') ==1
%     LLR_type= 'LLR_best';
% elseif strcmp(LLR_type,'fh') ==1
%     LLR_type= 'LLR_fh';
% elseif strcmp(LLR_type,'sh') ==1
%     LLR_type= 'LLR_sh';
% end

% LLR_type=char(LLR_type);


for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    if TG == 1
%         if strfind(root,'bestpm') ~= 0
            W = who('-file',path_file);
            varstruc =struct;
            load(path_file);
            for ii = 1:numel(W)
                varstruc.(W{ii}) = eval(W{ii});
            end
            
%             LikData = load(path_file,Lik_name);            
%             Lik_data = varstruc.(Lik_name).(LLR_type);
%             pIData = load(path_file,pI_name);
            pI_data = varstruc.(pI_name);
            
            fprintf([root '\n']);
            %cull pulses using pulse_model
%             culled_pulseInfo = cull_pulses(pI_data,Lik_data,[LLR_cutoff max(Lik_data)+1]);
            ipi = fit_ipi_model(pI_data.wc);
            
            varstruc.ipi = ipi;
            varstruc.ipi.variables.pulseInfo_ver = pI_name;
%             varstruc.ipi.variables.Lik_name = Lik_name;
%             varstruc.ipi.variables.LLR_type = LLR_type;
%             varstruc.ipi.variables.LLR_cutoff = LLR_cutoff;
            varstruc.ipi.variables.date = date;
            varstruc.ipi.variables.time = clock;
            save(path_file,'-struct','varstruc','-mat')%save all variables in original file

            
%             out_file = [folder sep root '_ipi.mat'];
%             save(out_file,'ipi','-mat')
%         end
    end
end

