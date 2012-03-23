function calcsineLombMulti(folder)
fs = 1e4;
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
            %test sine for periodicity
            lombStats = sineLomb(maxFFT,fs);
            
            varstruc.sineLomb = lombStats;
            
            varstruc.sineLomb.variables.date = date;
            varstruc.sineLomb.variables.time = clock;
            save(path_file,'-struct','varstruc','-mat')%save all variables in original file

    end
end



function lombStats = sineLomb(maxFFT,fs)


alphaThresh = 0.05;

[P,f,alpha]=lomb(maxFFT.freqAll,(maxFFT.timeAll)./fs);

%get peaks
peaks = regionalmax(P);
%get f,alpha,Peaks for peaks < desired alpha
fPeaks = f(peaks);
alphaPeaks = alpha(peaks);

signF = fPeaks(alphaPeaks < alphaThresh);
signAlpha = alphaPeaks(alphaPeaks <alphaThresh);
signPeaks = P(alphaPeaks < alphaThresh);

lombStats.F = signF;
lombStats.Alpha = signAlpha;
lombStats.Peaks = signPeaks;
