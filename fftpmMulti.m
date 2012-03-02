function [fileNames, maxfreqMulti] = fftpmMulti(folder,pulseModel_name)
%USAGE maxfreqMulti = fftpmMulti(folder)
%calculate dominant frequency in each pulse model in a folder

pM_name = char(pulseModel_name);


%grab models in a folder and put in cell array

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

fileNames = cell(1,file_num);
maxfreqMulti = zeros(file_num,1);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and calculating ffts\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        i = i+1;
%         if strfind(root,'pm') ~= 0
            %get plot data and limits
            pMData = load(path_file,pM_name);
            pulse_model = pMData.(pM_name);

            
%             load(path_file,'pulse_model');
            fileNames{i} = file;
            maxfreqMulti(i) = fftpm(pulse_model.fhM);
%         end
    end
end

fileNames(cellfun('isempty',fileNames))=[];
maxfreqMulti = maxfreqMulti(maxfreqMulti~=0);
