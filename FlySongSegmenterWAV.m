function FlySongSegmenterWAV(folder_of_folder_of_wav_files,song_range,params_path)

%Perform FlySongSegmenter on multiple channels from a single daq file
%e.g. FlySongSegmenterWAV('/misc/public/Troy/',[1 1000000],'./params.m');
%processes the first million tics 
%


%make directory for output
sep = filesep;
master_folder = folder_of_folder_of_wav_files;
subfolders = dir(master_folder);

for y = 1:numel(subfolders)
    folder_in_question = [master_folder subfolders(y).name];
    if ~strncmp(subfolders(y).name,'.',1)
        
        new_dir = [master_folder sep subfolders(y).name '_out' sep];
        mkdir(new_dir);
        files = dir([master_folder subfolders(y).name]);
        for i = 1:numel(files)
            file_in_question = [folder_in_question sep files(i).name];
            if ~strncmp(files(i).name,'.',1)  
                fprintf(['Grabbing song from wav file %s.\n'], file_in_question);
                if ~isempty(song_range)
                    song = wavread(file_in_question,'Samples',song_range);
                else
                    song = wavread(file_in_question);
                end
                
                %run FlySongSegmenter on selected channel
                %fprintf('Processing song.\n')
                [Data, Sines, Pulses, Params] = ...
                    FlySongSegmenter(song,[],params_path);
                
                %save data
                [pathstr, name, ext] = fileparts(file_in_question);
                outfile = [new_dir 'PS_' name '.mat'];
                save(outfile, 'Data','Sines','Pulses','Params','-v7.3');
                
                %clear workspace
                clear song Data Sines Pulses Params
            end
        end
    end
end
