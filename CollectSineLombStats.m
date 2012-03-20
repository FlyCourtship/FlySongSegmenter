function [file_names LombStats LombStatsMat] = CollectSineLombStats(folder)
%USAGE [file_names LombStats LombStatsMat] = CollectLombStats(folder)
if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

F = cell(1,file_num);
Alpha = cell(1,file_num);
Peaks = cell(1,file_num);
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
%         if strfind(root,'_ipi_ipiStatsLomb') ~= 0
            %get plot data and limits
            load(path_file,'sineLomb');
%             lomb = ipiStatsLomb.lomb;
            file_names{i} = file;
            F{i} = sineLomb.F;
            Alpha{i} = sineLomb.Alpha;
            Peaks{i} = sineLomb.Peaks;
%         end
    end
end

F(cellfun('isempty',F))=[];
Alpha(cellfun('isempty',Alpha))=[];
Peaks(cellfun('isempty',Peaks))=[];
file_names(cellfun('isempty',file_names))=[];

FMat=cat(1,F{:});
AlphaMat = cat(1,Alpha{:});
PeaksMat = cat(1,Peaks{:});

LombStats.F = F;
LombStats.Alpha = Alpha;
LombStats.Peaks = Peaks;
LombStatsMat.F = FMat;
LombStatsMat.Alpha = AlphaMat;
LombStatsMat.Peaks = PeaksMat;