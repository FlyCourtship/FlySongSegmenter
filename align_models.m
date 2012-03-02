function [aligned_models,file_names] = align_models(folder)
%USAGE aligned_models = align_models(folder)

%grab models in a folder and put in cell array

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

file_names = cell(1,file_num);
model_array = cell(1,file_num);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
%         if strfind(root,'pm') ~= 0
            %get plot data and limits
            load(path_file,'pulse_model');
            file_names{i} = file;
            model_array{i} = pulse_model.fhM';
%         end
    end
end

file_names(cellfun('isempty',file_names))=[];
model_array(cellfun('isempty',model_array))=[];

%collect and pad models
d = model_array;
n_samples = length(d);
max_length = max(cellfun(@length,d));
total_length = 2* max_length;
Z = zeros(n_samples,total_length );
if n_samples >1
    for n=1:n_samples
        X = d{n};
        T = length(X);
        [~,C] = max(abs(X));%get position of max power

        %flip model is strongest power is negative
        if X(C) <0
            X = -X;
        end
        
        %center on max power
        left_pad = max_length - C;  %i.e. ((total_length/2) - C)
        right_pad = total_length - T - left_pad;
        Z(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
    end
end


[Z,M] = alignpulses(Z,20);

RM = -M;
RZ = alignpulses2model(Z,RM);
RZ = scaleZ2M(RZ,RM);


for j = 2:n_samples
    M1 = Z(1,:);
    M2 = Z(j,:);
    RM2 = -M2;
    chisqF = mean((M1 - M2).^2./var(Z(n,:)));
    chisqR = mean((M1 - RM2).^2./var(Z(n,:)));
    if chisqR<chisqF
        M(j,:) = RM2;
    end
end


[Z,M] = alignpulses(Z,20);

aligned_models = Z;
[pathstr,name,~]=fileparts(folder);
r=regexp(pathstr,'/','split');
folder_name = char(r(end));
variables.date = date;
variables.time = clock;
    
outfile = [pathstr sep folder_name '_alignedmodels.mat'];
save(outfile,'aligned_models','file_names','variables','-mat');
