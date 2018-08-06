function song_quick_check_wav96(wavfile,channels,range)
%
%USAGE
%song_quick_check(wavfile,channels)
%
%for custom song snippet range
%song_quick_check(wavfile,channels,range)
%
%
%Takes output from array_take and performs a quick and simple analysis to
%find and display several snippets of putative song. Outputs ten plots of
%each channel. For channels, use first and last channel of a range. Use 
%consecutive numbers in recording device.
%
%e.g.s
%song_quick_check('20110624132239.wav',[2 7])
%
%custom range
%song_quick_check('20110624132239.wav',[2 7],1e4)


%Change this value if your wav file does not have 4 no-song channels
FetchParams;
number_nosong_channels = Params.wav_file_nosong_channels;
if nargin<3
    snippet_length = 2e4; 
else
    snippet_length = range;
end

[poolavail,isOpen] = check_open_pool;

if(~isdeployed)
addpath(genpath('./export_fig'));
addpath(genpath('./tight_subplot'));
addpath(genpath('./chronux'));
end

songinfo = audioinfo(wavfile);
nchannels = songinfo.NumChannels-number_nosong_channels;
fs = songinfo.SampleRate;
fprintf('wav file contains %s channels.\n', num2str(nchannels));
ncolumns = 5;

fprintf('Grabbing song from wav file %s.\n', wavfile);
if exist('sample','var')
    song = audioread(wavfile,sample);
else
    song = audioread(wavfile);
end


if exist('channels','var')
    start_channel = number_nosong_channels + channels(1);%start at first song channel
    end_channel = number_nosong_channels + channels(2);
else
    start_channel = number_nosong_channels + 1;%start at first song channel
    end_channel = number_nosong_channels + nchannels;
end

nchannels2plot = end_channel - start_channel + 1;
param.low_freq_cutoff = 100;
param.high_freq_cutoff = 200;
param.cutoff_sd = 3;

%make array to store data
snippets = zeros(nchannels2plot,ncolumns,snippet_length+1);

for y = start_channel:end_channel
    channel_song = song(:,y);
    if length(channel_song) > 5e6
        snip = channel_song(1:5e6);
    else
        snip = channel_song;
    end
    
    %grab short snip of song to find noise
    fprintf('Finding noise.\n')
    [ssf] = MultiTaperFTest(snip,fs,12,20,.1,.05,.05); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
    
    %find noise
    try%sometimes may fail to generate noise file. Then, just abort plot
        xempty = EstimateNoise(channel_song,ssf,Params,param.low_freq_cutoff,param.high_freq_cutoff);
    catch
        fprintf('EstimateNoise failed')
    end
    if exist('xempty','var')
        % noise.sigma = std(xempty);
        noise = 'noise';
        cutoff = 5 * xempty.sigma;
    else
        noise = 'nonoise';
        cutoff = 5*5e-3;
    end
    
    if strcmp(noise,'noise') == 1

        %find ncolumns of events that exceed cutoff
        
        signal = find(channel_song > cutoff);
        
        if numel(signal) >= ncolumns;
            samples = randsample(signal,ncolumns);
            rep = 0;
            while any(samples-snippet_length <0) || any(samples+snippet_length >length(song))%this is to ensure that plotted values are included in song
                samples = randsample(signal,ncolumns);
                rep=rep+1;
                if rep == 1000
                    samples = zeros(1,ncolumns);
                    break
                end
            end
        else
            %if no song found
            samples = zeros(1,ncolumns);
        end
        
        %store snippets
        for i = 1:ncolumns
            snippets(y-start_channel+1,i,:) = channel_song(samples(i) - snippet_length/2 :samples(i) + snippet_length/2);
        end
    
    else
        
        %could not extract noise, take ncolumns loud bits
        signal = find(channel_song > 3 * std(channel_song));
        if numel(signal) >= ncolumns;
            samples = randsample(signal,ncolumns);
            rep = 0;
            while any(samples-snippet_length <0) || any(samples+snippet_length >length(channel_song))%this is to ensure that plotted values are included in song
                samples = randsample(signal,ncolumns);
                rep=rep+1;
                if rep == 1000
                    samples = zeros(1,ncolumns);
                    break
                end
            end
        else
            %if no song found
            samples = zeros(1,ncolumns);
        end
        
        for i = 1:ncolumns
            snippets(y-number_nosong_channels,i,:) = channel_song(samples(i) - snippet_length:samples(i) + snippet_length);
        end
    end
end

h = figure('OuterPosition',[0 0 ncolumns*200 nchannels2plot*100]);
ax = tight_subplot(nchannels2plot,ncolumns+1,[.005 .01],[.01 .01],[.01 .01]);

fprintf('Plotting some results.\n')
handle = 0;
for channel = start_channel:end_channel
    for column = 1:ncolumns+1
        handle = handle + 1;
        axes(ax(handle));
        if column == 1
            row = sprintf(['Channel ' num2str(channel)]);
            text(0,.5,row,'FontSize',10);
        else
            if sum(abs(snippets(channel-start_channel + 1,column-1,1:100))) ~= 0; %check to make sure has song
                axis([1 snippet_length+1 -10*cutoff 10*cutoff])
                plot(1:snippet_length+1,squeeze(snippets(channel-start_channel + 1,column-1,:)),'k')
                xlim([1 snippet_length+1])
                ylim([-10*cutoff 10*cutoff])
            else
                %if no song, plot flatline
                plot([1 2],[0 0],'k')
                axis([1 2 -10*cutoff 10*cutoff])
                xlim([1 snippet_length+1])
                ylim([-10*cutoff 10*cutoff])
            end
        end
        axis off
    end
end


check_close_pool(poolavail,isOpen)

fprintf('Saving figure.\n')
[pathstr, name, ~] = fileparts(wavfile);
fileName_channels = sprintf('_ch%d-%d',start_channel,end_channel);
outfile = [pathstr filesep name '_ch' fileName_channels '.png'];
warning('off','MATLAB:LargeImage')
export_fig(outfile,'-r300');
close(h);
    
