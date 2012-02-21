function aligned_models = align_models(folder)

%grab models in a folder and put in cell array

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

model_array = cell(1,file_num);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
        if strfind(root,'pm') ~= 0
            %get plot data and limits
            load(path_file,'pulse_model');
            model_array{i} = pulse_model.fhM';
        end
    end
end

model_array = model_array(1:i);

%align models
d = model_array;
n_samples = length(d);
max_length = max(cellfun(@length,d));
total_length = 2* max_length;
Z = zeros(n_samples,total_length );
if n_samples >1
    for n=1:n_samples;
        X = d{n};
        T = length(X);
        [~,C] = max(X);%get position of max power
        
        %center on max power
        left_pad = max_length - C;  %i.e. ((total_length/2) - C)
        right_pad = total_length - T - left_pad;
        Z(n,:) = [zeros(left_pad,1); X ;zeros((right_pad),1)];
    end
end
aligned_models = Z;
