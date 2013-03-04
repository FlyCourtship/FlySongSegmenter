function pulses=GrabPulsesFromFolder(folder)

%get _out folder info
dir_list = dir(folder);
file_num = numel(dir_list);

pulses = {};

for y = 1:file_num
    
    file = dir_list(y).name; %pull out the file name
    fprintf([file '\n']);
    [~,~,ext] = fileparts(file);
    path_file = [folder file];
    if strcmp(ext,'.mat');
        load(path_file)
        x = GetClips(Pulses.IPICull.w0,Pulses.IPICull.w1,Data.d);
        pulses = cat(2,pulses,x);
    end
end

