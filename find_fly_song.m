function find_fly_song(song_path, varargin)
    % Convert Unix-style command line arguments to MATLAB-style.
    varargin = regexprep(varargin, '^-p$', 'params_path');
    varargin = regexprep(varargin, '^-s$', 'sample_range');
    varargin = regexprep(varargin, '^-c$', 'channel_num');
    
    p = inputParser;
    p.addRequired('song_path', @ischar);
    p.addParamValue('params_path', '', @ischar);
    p.addParamValue('sample_range', '', @(x)isempty(x) || ~isempty(regexp(x, '^[0-9]*:[0-9]*$', 'once')));
    p.addParamValue('channel_num', '', @(x)isempty(x) || ~isempty(regexp(x, '^[0-9]*$', 'once')));
    try
        p.parse(song_path, varargin{:});
    catch ME
        disp(ME.message);
        disp('Usage:');
        disp('    find_fly_song song_path [-p params_path] [-s sample_range] [-c channel_num]');
        disp('e.g.');
        disp('    find_fly_song song.wav -p params.m -s 1000:2000 -c 7');
        return
    end
    
    if isempty(p.Results.sample_range)
        sample_range = [];
    else
        tokens = regexp(p.Results.sample_range, '^([0-9]*):([0-9]*)$', 'tokens');
        sample_range = [str2double(tokens{1}{1}) str2double(tokens{1}{2})];
    end
    
    [~, ~, ext] = fileparts(p.Results.song_path);
    if strcmp(ext, '.daq')
        Process_daq_Song(p.Results.song_path, str2num(p.Results.channel_num), sample_range, p.Results.params_path);
    elseif strcmp(ext, '.wav')
        if(~isempty(p.channel_num))
          error('-c channel_num only valid with .daq files');
        end
        [data, Fs] = wavread(p.Results.song_path);
        process_song_data(song_path, data, Fs, sample_range, p.Results.params_path);
    elseif strcmp(ext, '.au')
        if(~isempty(p.channel_num))
          error('-c channel_num only valid with .daq files');
        end
        [data, Fs] = auread(p.Results.song_path);
        process_song_data(song_path, data, Fs, sample_range, p.Results.params_path);
    else
        error('Unknown song file format: %s', ext);
    end
end


function process_song_data(song_path, song_data, Fs, sample_range, params_path)
    [parentDir, song_name, ~] = fileparts(song_path);
    outfile  = fullfile(parentDir, [song_name '.mat']);
    if ~exist(outfile, 'file')
        if ~isempty(sample_range)
            song_data = song_data(sample_range(1):sample_range(2));
        end
        [data, winnowed_sine, pulseInfo2, pulseInfo] = Process_Song(song_data, Fs, [], params_path); %#ok<NASGU,ASGLU>
        save(outfile, 'data','winnowed_sine','pulseInfo2','pulseInfo','-v7.3')
        clear song data winnowed_sine pulseInfo2 pulseInfo;
    else
        fprintf('File %s exists. Skipping.\n', outfile)
    end
end
