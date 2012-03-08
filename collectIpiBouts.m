function collectIpiBouts(folder)



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
        %         if strfind(root,'_ipi_ipiStatsLomb') ~= 0
        %get culled_ipi data and times
        load(path_file,'ipiStatsLomb');
        culled_ipi = ipiStatsLomb.culled_ipi;
        
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
            if t(i) - t(i-1) ~= d(i-1)%collect ipis where the ipi matches the distance between pulses
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
        
        
        %
        %             out_file = [folder sep root '_bouts.mat'];
        %             save(out_file,'ipis','times','-mat')
        
        
        W = who('-file',path_file);
        varstruc =struct;
        load(path_file);
        for ii = 1:numel(W)
            varstruc.(W{ii}) = eval(W{ii});
        end
        varstruc.ipiBouts.d= ipis;
        varstruc.ipiBouts.t= times;
        
        varstruc.ipiBouts.variables.date = date;
        varstruc.ipiBouts.variables.time = clock;
        save(path_file,'-struct','varstruc','-mat')%save all variables in original file
        
        %         end
    end
end

