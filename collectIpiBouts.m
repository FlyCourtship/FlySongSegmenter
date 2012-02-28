function collectIpiBouts(folder)

%collect bouts from culled_ipi found in _bestpm_ipi_ipiStatsLomb files


sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);
i= 0;

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
            %get culled_ipi data and times
            load(path_file,'culled_ipi');
           
            
            %grab indexes for start and stop of bouts (cols 1 and 2 of
            %boutIdx)
            d = culled_ipi.d;
            t = culled_ipi.t;
            numIpis = numel(culled_ipi.d);
            %set up arrays
            startIdx = zeros(numIpis,1);
            stopIdx = zeros(numIpis,1);
            j = 1;
            startIdx(j) = 1;

            x = [];
            for i = 2:numel(t);
                if t(i) - t(i-1) ~= d(i-1)
                    stopIdx(j) = i-1;
                    j=j+1;
                    startIdx(j) = i;
                    
                    x(j) = t(i);
                end
            end
            stopIdx(j) = i;
            
            startIdx(startIdx == 0) = [];
            stopIdx(stopIdx == 0) = [];
            
            numBouts = numel(startIdx);
            ipis = cell(1,numBouts);
            times = cell(1,numBouts);

            for i = 1:numBouts
                ipis{i} = d(startIdx(i):stopIdx(i));
                times{i} = t(startIdx(i):stopIdx(i));
            end
            
            out_file = [folder sep root '_bouts.mat'];
            save(out_file,'ipis','times','-mat')

        end
    end
end

