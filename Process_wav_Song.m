function Process_wav_Song(folder,noise_file,song_range,noise_range)

%NEEDS TO BE UPDATED TO CALL NEW VERSION OF PROCESS_SONG
%6-9-11

sep = filesep;
dir_list = dir(folder);

file_num = length(dir_list);
for y = 1:file_num
    file = dir_list(y).name;
    [path,name,ext] = fileparts(file);
    path_file = [folder sep file];
    TF = strcmp(path_file,noise_file);
    if TF ~= 1%don't process noise file
        TG = strcmp(ext,'.wav');
        if TG == 1
            fprintf(['Reading song from file %s.\n'], file)
            [song,Fs] = wavread(path_file);
            fprintf(['Reading noise from file %s.\n'], noise_file)
            [noise,noise_Fs] = wavread(noise_file);
            
            outfile = [folder sep 'PS_' name '.mat'];
            file_exist = exist(outfile,'file');
            
            if file_exist == 0;%if file exists, skip
                
                %run Process_Song on selected channel
                fprintf('Processing song.\n')
                [ssf,winnowed_sine, pps, pulseInfo2, pulseInfo, pcndInfo] = Process_Song(song,noise);

                %save data
                save(outfile, 'ssf','noise_ssf','winnowed_sine','pps',...
                    'pulseInfo2','pulseInfo','pcndInfo')
                %clear workspace
                clear song noise ssf noise_ssf winnowed_sine pps pulseInfo2 pulseInfo pcndInfo
            else
                fprintf(['File %s exists. Skipping.\n'], outfile)
            end
        end
    end
end

