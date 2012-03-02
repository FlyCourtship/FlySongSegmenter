function combined_pulse_model = combineMultipleModels(folder,pulse_model_name)
%USAGE combined_pulse_model = combineMultipleModels(folder,pulse_model_name)
%build a pulse model from the data present in a pulsemodel structure 
%from multiple individuals

%pulse_model_name is a string indicating pulse_model to pool
% 'pulse_model' or 'culled_pulse_model'

if nargin <2
    fprintf('You must also enter the pulse_model to analyze as a string. e.g. "culled_pulse_model"\n')
    return
else
    pm_name = char(pulse_model_name);
end


[poolavail,isOpen] = check_open_pool;


%grab models in a folder and put in cell array

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

file_names = cell(1,file_num);
fhZ_size = zeros(file_num,1);
shZ_size = zeros(file_num,1);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
%         if strfind(root,'pm') ~= 0
            %get plot data and limits
            pM = load(path_file,pm_name);
            file_names{i} = file;
            
            fhZ_size(i) = size(pM.(pm_name).fhZ,1);
            shZ_size(i) = size(pM.(pm_name).shZ,1);
%         end
    end
end

file_names(cellfun('isempty',file_names))=[];
fhZ_size = fhZ_size(fhZ_size~=0);
shZ_size = shZ_size(shZ_size~=0);
numfhZ = sum(fhZ_size);
numshZ = sum(shZ_size);

file_num = numel(file_names);
fhZAll = cell(1,numfhZ);
shZAll = cell(1,numshZ);

fprintf('Collecting pulses from all files\n');
%collect data from each file
fhZNum = 0;
shZNum = 0;
for y = 1:file_num
    %reload each file
    path_file = [folder file_names{y}];
    pM = load(path_file,pm_name);
    %
    %pad old data
    %
    
%     delta = length(pulse_model.fhM);
%     left_pad = round(delta/2);
%     right_pad = delta -left_pad;
    fhZ = pM.(pm_name).fhZ;
    shZ = pM.(pm_name).shZ;
%     fhZ = [zeros(size(fhZ,1),left_pad) fhZ zeros(size(fhZ,1),right_pad)];
%     shZ = [zeros(size(shZ,1),left_pad) shZ zeros(size(shZ,1),right_pad)];
    
    for i = 1:fhZ_size(y)
        %keep running count of numbers
        fhZNum = fhZNum + 1;
        fhZAll{fhZNum} = fhZ(i,:);
    end
    for i = 1:shZ_size(y)
        %keep running count of numbers
        shZNum = shZNum + 1;
        shZAll{shZNum} = shZ(i,:);
    end
end


%Make new models
fprintf('Making first harmonic model\n');
%grab samples, center, and pad
%first harmonic
n_samples = numfhZ;
max_length = max(cellfun(@length,fhZAll));
total_length = 2* max_length;
fhZ = zeros(n_samples,total_length );
parfor n=1:n_samples;
    X = fhZAll{n}';
    T = length(X);
    [~,C] = max(X);%get position of max power
    
    %center on max power
    left_pad = max_length - C;  %i.e. ((total_length/2) - C)
    right_pad = total_length - T - left_pad;
    fhZ(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
end

[fhZ,fhM] = alignpulses(fhZ,20);

%second harmonic
fprintf('Making second harmonic model\n');
n_samples = numshZ;
max_length = max(cellfun(@length,shZAll));
total_length = 2* max_length;
shZ = zeros(n_samples,total_length );
parfor n=1:n_samples;
    X = shZAll{n}';
    T = length(X);
    [~,C] = max(X);%get position of max power
    
    %center on max power
    left_pad = max_length - C;  %i.e. ((total_length/2) - C)
    right_pad = total_length - T - left_pad;
    shZ(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
end

[shZ,shM] = alignpulses(shZ,20);

%Trim models to useful lengths

%compare SE at each point (from front and back) with deviation of fh model
%start and stop when deviation exceeds SE of data
%for first harmonic
S_Z = std(fhZ(fhZ ~= 0));%take only data that are not 0 (i.e. padding)
SE_Z = S_Z/sqrt(numfhZ);
start = find((abs(fhM)>SE_Z),1,'first');
finish = find((abs(fhM)>SE_Z),1,'last');
fhM  = fhM(start:finish);
fhZ = fhZ(:,start:finish);
fhS = std(fhZ);

%for second harmonic
S_Z = std(shZ(shZ ~= 0));%take only data that are not 0 (i.e. padding)
SE_Z = S_Z/sqrt(numshZ);
start = find((abs(shM)>SE_Z),1,'first');
finish = find((abs(shM)>SE_Z),1,'last');
shM  = shM(start:finish);
shZ = shZ(:,start:finish);
shS = std(shZ);


combined_pulse_model.fhM = fhM;
combined_pulse_model.shM = shM;
combined_pulse_model.fhZ = fhZ;
combined_pulse_model.shZ = shZ;
combined_pulse_model.fhS = fhS;
combined_pulse_model.shS = shS;


check_close_pool(poolavail,isOpen);
