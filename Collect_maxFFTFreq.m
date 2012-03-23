function [file_names, SINEFFTfreq, SINEFFTtimes,BoutsStart,BoutsStop] = Collect_maxFFTFreq(folder)
%USAGE  [file_names Pauses PausesMat] = CollectBouts(folder)

if strcmp(folder(end),'/') == 0
    folder = [folder '/'];
end
dir_list = dir(folder);
file_num = length(dir_list);
i=0;

SINEFFTfreq = cell(1,file_num);
SINEFFTtimes = cell(1,file_num);
file_names = cell(1,file_num);
BoutsStart = cell(1,file_num);
BoutsStop = cell(1,file_num);

%get file names and sample sizes for fhZ and shZ
fprintf('Grabbing file names and data sizes\n');
for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder file];
    TG = strcmp(ext,'.mat');
    
    if TG == 1 %if it is a .mat file
        i = i+1;
            %get plot data and limits
            load(path_file,'maxFFT');
            load(path_file, 'bouts');
            file_names{i} = file;
            SINEFFTfreq{i} = maxFFT.freqAll;
            SINEFFTtimes{i} = maxFFT.timeAll;
            BoutsStart{i} = bouts.Start;
            BoutsStop{i} = bouts.Stop;
    end
end

SINEFFTfreq(cellfun('isempty',SINEFFTfreq))=[];
SINEFFTtimes(cellfun('isempty',SINEFFTtimes))=[];
file_names(cellfun('isempty',file_names))=[];
BoutsStart(cellfun('isempty',BoutsStart))=[];
BoutsStop(cellfun('isempty',BoutsStop))=[];

%Bouts=cat(1,Bouts{:});









