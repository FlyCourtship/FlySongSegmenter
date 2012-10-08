function makeBestModels(folder,pulseInfo_name,Lik_name,LLR_type,cull_thresh)
%USAGE makeBestModels(folder,pulseInfo_ver,Lik_name,LLR_type,cull_thresh)
%pulseInfo_name can take 'pulseInfo', 'pulseInfo2', etc.
%Lik_name = e.g. 'Lik_pulse', 'culled_Lik_pulse' etc
%LLR_type = 'best', 'fh', or 'sh'


Lik_name = char(Lik_name);
pI_name = char(pulseInfo_name);

if strcmp(LLR_type,'best') ==1
    LLR_type= 'LLR_best';
elseif strcmp(LLR_type,'fh') ==1
    LLR_type= 'LLR_fh';
elseif strcmp(LLR_type,'sh') ==1
    LLR_type= 'LLR_sh';
end

LLR_type=char(LLR_type);

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end


fprintf(['Analyzing folder' folder  '\r'])
dir_list = dir(folder);
file_num = length(dir_list);
files = cell(file_num,1);
for y = 1:file_num
    directory = dir_list(y).name;
    file = directory; %pull out the file name
    [~,~,ext] = fileparts(file);
    if strcmp(ext,'.mat');
        files{y} = file;
    end
    files(cellfun('isempty',files))=[];
end

% now load files one at a time and the pulsemodel file in another folder
file_num = length(files);
for j = 1:file_num
    file = [folder files{j}];
    fprintf(['Analyzing file' file  '\r'])
      
    LikData = load(file,Lik_name);
    Lik_data = LikData.(Lik_name).(LLR_type);
    pIData = load(file,pI_name);
    pI_data = pIData.(pI_name);
    
    
    load(file,'Lik_pulse')
      
    if numel(Lik_data) ~= numel(pI_data.x)
        fprintf('pulseInfo and Lik_pulse have different number of entries. Please choose the correct pulseInfo structure to analyse.\n')
        continue
    end
    
    %cull data to LLR range. In this case > 0
    culled_pulseInfo = CullPulses(pI_data,Lik_data,[cull_thresh max(Lik_data)+1]);
    [culled_pulse_model,culled_Lik_pulse] = FitPulseModel(culled_pulseInfo.x);
    
    W = who('-file',file);
    varstruc =struct;
    load(file);
    for ii = 1:numel(W)
        varstruc.(W{ii}) = eval(W{ii});
    end
    varstruc.culledModel.pulseInfo = culled_pulseInfo;
    varstruc.culledModel.Lik_pulse = culled_Lik_pulse;
    varstruc.culledModel.pulse_model = culled_pulse_model;
    
    varstruc.culledModel.variables.pulseInfo_ver = pI_name;
    varstruc.culledModel.variables.Lik_name = Lik_name;
    varstruc.culledModel.variables.LLR_type = LLR_type;
    varstruc.culledModel.variables.cull_thresh = cull_thresh;
    varstruc.culledModel.variables.date = date;
    varstruc.culledModel.variables.time = clock;
    save(file,'-struct','varstruc','-mat')%save all variables in original file
        
end
