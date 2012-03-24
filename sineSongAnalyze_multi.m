function sineSongAnalyze_multi(folder)
%[poolavail,isOpen] = check_open_pool;
if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    if TG == 1
            W = who('-file',path_file);
            varstruc =struct;
            load(path_file);
            for ii = 1:numel(W)
                varstruc.(W{ii}) = eval(W{ii});
            end
            
            fprintf([root '\n']);
            %calc sine fund freq
            maxFFT = sine_song_analyze2(winnowed_sine);
            
            varstruc.maxFFT = maxFFT;
            
            varstruc.sineLomb.variables.date = date;
            varstruc.sineLomb.variables.time = clock;
            save(path_file,'-struct','varstruc','-mat')%save all variables in original file

    end
end

%check_close_pool(poolavail,isOpen);
