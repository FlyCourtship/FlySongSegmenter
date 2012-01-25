function Process_multi_daq_Song(folder,song_range)

%old - when require noise file
%function Process_daq_Song(song_daq_file,song_range)
%This function allows you to analyze mutiple daqs in a folder and gives you
%outputs in separate folders.
poolavail = exist('matlabpool','file');%check if toolbox is available
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
        matlabpool(getenv('NUMBER_OF_PROCESSORS'))
        isOpen = -1;%now know pool was opened in this scripts (no negative pools from matlabpool('size'))
    end
end

sep = filesep;
dir_list = dir(folder);

file_num = length(dir_list);



for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,name,ext] = fileparts(file);
    path_file = [folder sep file];
    TG = strcmp(ext,'.daq');
    
    if TG == 1
        song_daqinfo = daqread(path_file,'info');
        %noise_daqinfo = daqread(noise_daq_file,'info');
        
        % if nargin == 3
        %     song_range = song_range;
        % elseif nargin == 4
        %     song_range = song_range;
        %     noise_range = noise_range;
        % end
        
        %Produce batch process file, with daq
        
        nchannels_song = length(song_daqinfo.ObjInfo.Channel);
        %nchannels_noise = length(noise_daqinfo.ObjInfo.Channel);
        
        %make directory for output
        
        new_dir = [folder sep name '_out'];
        mkdir(new_dir);
        
        
        for i = 1:nchannels_song
            outfile = [new_dir sep 'PS_' name '_ch' num2str(i) '.mat'];
            file_exist = exist(outfile,'file');
            if file_exist == 0;%if file exists, skip
                %grab song and noise from each channel
                fprintf('Grabbing song and noise from daq file channel %s.\n', name)
                if nargin ==2
                    song = daqread(path_file,'Channels',i,'Samples',song_range);
                    %noise = daqread(noise_daq_file,'Channels',y);
                    %elseif nargin ==4
                    %   song = daqread(song_daq_file,'Channels',y,'Samples',song_range);
                    %  noise = daqread(noise_daq_file,'Channels',y,'Samples',noise_range);
                else
                    song = daqread(path_file,'Channels',i);
                    %noise = daqread(noise_daq_file,'Channels',y);
                end
                %grab sample rate from daq and replace value in params, with
                %warning
%                 fs = song_daqinfo.ObjInfo.SampleRate;
%                 fprintf('Using sample rate from daq file\n')
%                 
                %run Process_Song on selected channel
                fprintf('Processing song.\n')
                [data, winnowed_sine, pulseInfo2, pulseInfo] = Process_daq_Song(song);
                %save data
                
                save(outfile, 'data','winnowed_sine','pulseInfo2','pulseInfo','-v7.3')
                %save(outfile, 'data','ssf','winnowed_sine',...
                %'pulseInfo2','pulseInfo','pcndInfo','-v7.3')
                %clear workspace
                clear song data winnowed_sine pulseInfo2 pulseInfo
            else
                fprintf('File %s exists. Skipping.\n', outfile)
            end
        end
        
    else
        fprintf(['File %s exists. Skipping.\n'])
    end
end
if isOpen == -1%if pool opened in this script, then close
    if poolavail~=0
        matlabpool close force local
    end
end

