function song_quick_check(daqfile)
%USAGE
%song_quick_check(daqfile)
%
%Takes output from array_take and performs a quick and simple analysis to
%find and display several snippets of putative song. Outputs three plots of
%each channel.

addpath(genpath('./export_fig'))
addpath(genpath('./tight_subplot'))
addpath(genpath('./chronux'))

daqinfo = daqread(daqfile,'info');
nchannels = length(daqinfo.ObjInfo.Channel);
fs = daqinfo.ObjInfo.SampleRate;
ncolumns = 10;

param.low_freq_cutoff = 100;
param.high_freq_cutoff = 200;
param.cutoff_sd = 3;
plotnum = 0;

ax = tight_subplot(nchannels,ncolumns+1,[.005 .01],[.01 .01],[.01 .01]);

for y = 1:nchannels
    fprintf(['Grabbing channel %s.\n'], num2str(y))
    song = daqread(daqfile,'Channels',y);
    snip = song(1:3e5);
    
    %grab short snip of song to find noise
    fprintf('Finding noise.\n')
    [ssf] = sinesongfinder(snip,fs,10,6,.1,.05,.05); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
    
    %find noise
    try%sometimes may fail to generate noise file. Then, just abort plot
        xempty = segnspp(ssf,param);
    catch
        xempty = 0;
    end
    %fprintf('Running multitaper analysis on noise.\n')
    %[noise_ssf] = sinesongfinder(xempty,fs,20,12,.1,.01,.05); %returns noise_ssf
        
    
    if xempty ~= 0
        cutoff = 5 * std(xempty);
        
        %%
        %Now find 5 segments of 3 seconds each with events that exceed cutoff
        
        signal = find(song > cutoff);
        
        samples = randsample(signal,ncolumns);
        while any(samples-2e4<0) || any(samples+2e4>length(song))%this is to ensure that plotted values are included in song
            samples = randsample(signal,ncolumns);
        end
        
        
        fprintf('Plotting some results.\n')
        
        for i = 1:ncolumns+1
            plotnum = plotnum + 1;
            axes(ax(plotnum))
            if i == 1
                row = ['Channel ' num2str(y)];
                text(0,.5,row,'FontSize',10);
            else               
                plot(1:3e4+1,song(samples(i-1) - 1.5e4:samples(i-1) + 1.5e4),'k')
            end
            axis off
            axis tight
            
        end
        
    else
        for i = 1:ncolumns+1
            %could not extract noise, take 5 loud bits
            signal = find(song > 3 * std(song));
            samples = randsample(signal,ncolumns);
            plotnum = plotnum + 1;
            axes(ax(plotnum))
            if i == 1
                row = ['Channel ' num2str(y) ':Error'];
                text(0,.5,row,'FontSize',10);
            else
                plot(1:3e4+1,song(samples(i-1) - 1.5e4:samples(i-1) + 1.5e4),'k')
            end
            axis off
            axis tight
            
        end
    end
    
    clear xempty
    
end

fprintf('Saving figure.\n')
outfile = ['Channels_1 -' num2str(y) '.png'];
warning('off','MATLAB:LargeImage')
export_fig(outfile,'-r300');
    