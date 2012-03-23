function [file_names Pauses PausesMat] = CollectPauses(folder)
%USAGE [file_names Pauses PausesMat] = CollectPauses(folder)
if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end

dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

PauseDelta = cell(1,file_num);
sinesine = cell(1,file_num);
sinepulse = cell(1,file_num);
pulsesine = cell(1,file_num);
pulsepulse = cell(1,file_num);
file_names = cell(1,file_num);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
            %get plot data and limits
            load(path_file,'pauses');
            file_names{i} = file;
            PauseDelta{i} = pauses.PauseDelta;
            sinesine{i} = pauses.sinesine;
            sinepulse{i} = pauses.sinepulse;
            pulsesine{i} = pauses.pulsesine;
            pulsepulse{i} = pauses.pulsepulse;

    end
end

PauseDelta(cellfun('isempty',PauseDelta))=[];
sinesine(cellfun('isempty',sinesine))=[];
sinepulse(cellfun('isempty',sinepulse))=[];
pulsesine(cellfun('isempty',pulsesine))=[];
pulsepulse(cellfun('isempty',pulsepulse))=[];
file_names(cellfun('isempty',file_names))=[];

PauseDeltaMat=cat(1,PauseDelta{:});
sinesineMat = cat(1,sinesine{:});
sinepulseMat = cat(1,sinepulse{:});
pulsesineMat = cat(1,pulsesine{:});
pulsepulseMat = cat(1,pulsepulse{:});


Pauses.PauseDelta = PauseDelta;
Pauses.sinesine = sinesine;
Pauses.sinepulse = sinepulse;
Pauses.pulsesine = pulsesine;
Pauses.pulsepulse = pulsepulse;

PausesMat.PauseDelta = PauseDeltaMat;
PausesMat.sinesine = sinesineMat;
PausesMat.sinepulse = sinepulseMat;
PausesMat.pulsesine = pulsesineMat;
PausesMat.pulsepulse = pulsepulseMat;
