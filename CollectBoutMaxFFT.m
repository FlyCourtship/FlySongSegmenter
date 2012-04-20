function BoutsMaxFFT = CollectBoutMaxFFT(folder)

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

allTime = [];
allFreq = [];

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1
        
        load(path_file,'bout_maxFFT');
        %         file_names{i} = file;
        for j = 1:numel(bout_maxFFT.time)
            allTime = catpad(1,allTime,bout_maxFFT.time{j});
            allFreq = catpad(1,allFreq,bout_maxFFT.freq{j});
        end            
    end
end

BoutsMaxFFT.allTime = allTime;
BoutsMaxFFT.allFreq = allFreq;

% BoutsMaxFFT(cellfun('isempty',BoutsMaxFFT))=[];
% file_names(cellfun('isempty',file_names))=[];
% 
% BoutsMaxFFT=cat(1,BoutsMaxFFT{:});









