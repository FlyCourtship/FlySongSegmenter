function [file_names ipiStatsAll]  = CollectIpiStats(folder)


sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

mu1 = zeros(file_num,1);
mu2 = zeros(file_num,1);
Sigma1 = zeros(file_num,1);
Sigma2 = zeros(file_num,1);
N = zeros(file_num,1);
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
        if strfind(root,'_ipi_ipiStatsLomb') ~= 0
            %get plot data and limits
            load(path_file,'ipiStats','culled_ipi');
            file_names{i} = file;
            mu1(i) = ipiStats.mu1;
            mu2(i) = ipiStats.mu2;
            Sigma1(i) = ipiStats.S1;
            Sigma2(i) = ipiStats.S2;
            N(i) = numel(culled_ipi.d);
        end
    end
end

ipiStatsAll.mu1 = mu1(mu1~=0);
ipiStatsAll.mu2 = mu2(mu2~=0);
ipiStatsAll.Sigma1 = Sigma1(Sigma1~=0);
ipiStatsAll.Sigma2 = Sigma2(Sigma2~=0);
ipiStatsAll.N = N(Sigma2~=0);
file_names(cellfun('isempty',file_names))=[];
