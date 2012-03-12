function song_quick_check(daqfile,sample,channels)
%USAGE
%song_quick_check(daqfile)
%
%Check only a portion of each channel
%song_quick_check(daqfile,[start finish])
%
%Check only a portion of only some channels
%song_quick_check(daqfile,[start finish],channels)
%
%Check the entire length of only some channels
%song_quick_check(daqfile,[],channels)
%
%
%e.g.s
%
%%song_quick_check('20110624132239.daq')
%
%Check only a portion of each channel
%song_quick_check('20110624132239.daq',[1e5 5e6])
%
%Check only a portion of only some channels
%song_quick_check('20110624132239.daq',[1 5e6],[2 4 7])
%
%Check the entire length of only some channels
%song_quick_check('20110624132239.daq',[],[2 4 7])
%Takes output from array_take and performs a quick and simple analysis to
%find and display several snippets of putative song. Outputs three plots of
%each channel.

poolavail = exist('matlabpool','file');
if poolavail~=0
    isOpen = matlabpool('size') > 0;%check if pools open (as might occur, for eg if called from Process_multi_daq_Song
    if isOpen == 0%if not open, then open
        matlabpool(getenv('NUMBER_OF_PROCESSORS'))
        isOpen = -1;%now know pool was opened in this script (no negative pools from matlabpool('size'))
    end
end

addpath(genpath('./export_fig'))
addpath(genpath('./tight_subplot'))
addpath(genpath('./chronux'))

daqinfo = daqread(daqfile,'info');
nchannels = length(daqinfo.ObjInfo.Channel);
fs = daqinfo.ObjInfo.SampleRate;
ncolumns = 10;

if exist('channels','var')
    nchannels = numel(channels);
    %then channels will be provided
else
    channels =1:nchannels;
end



param.low_freq_cutoff = 100;
param.high_freq_cutoff = 200;
param.cutoff_sd = 3;
plotnum = 0;
clf;
h = figure('OuterPosition',[0 0 ncolumns*200 nchannels*100]);
ax = tight_subplot(nchannels,ncolumns+1,[.005 .01],[.01 .01],[.01 .01]);

for y = channels
    fprintf(['Grabbing channel %s.\n'], num2str(y))
    if exist('sample','var')
        if isempty(sample)
            song = daqread(daqfile,'Channels',y);
        else
            song = daqread(daqfile,'Channels',y,'Samples',sample);
        end
    else
        song = daqread(daqfile,'Channels',y);
    end
    if length(song) > 5e6
        snip = song(1:5e6);
    else
        snip = song;
    end
    
    %grab short snip of song to find noise
    fprintf('Finding noise.\n')
    [ssf] = sinesongfinder(snip,fs,12,20,.1,.05,.05); %returns ssf, which is structure containing the following fields: ***David, please explain each field in ssf
    
    %find noise
     try%sometimes may fail to generate noise file. Then, just abort plot
        xempty = findnoise(ssf,param,param.low_freq_cutoff,param.high_freq_cutoff);
     catch
         fprintf('findnoise failed')
     end
     if isfield(xempty,'sigma')
         % noise.sigma = std(xempty);
         noise = 'noise';
         cutoff = 5 * xempty.sigma;
     else
         noise = 'nonoise';
         cutoff = 5*5e-3;
     end
     %fprintf('Running multitaper analysis on noise.\n')
     %[noise_ssf] = sinesongfinder(xempty,fs,20,12,.1,.01,.05); %returns noise_ssf
        
    if strcmp(noise,'noise') == 1
        
        
        %%
        %Now find ncolumns of events that exceed cutoff
        
        signal = find(song > cutoff);
        
        if numel(signal) >= ncolumns;
            samples = randsample(signal,ncolumns);
            rep = 0;
            while any(samples-2e4<0) || any(samples+2e4>length(song))%this is to ensure that plotted values are included in song
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
        
        
        
        fprintf('Plotting some results.\n')
        
        for i = 1:ncolumns+1
            plotnum = plotnum + 1;
            axes(ax(plotnum))
            if i == 1
                row = sprintf(['Channel ' num2str(y)]);
                text(0,.5,row,'FontSize',10);
            else
                if samples(i-1) ~= 0;
                    plot(1:3e4+1,song(samples(i-1) - 1.5e4:samples(i-1) + 1.5e4),'k')
                    axis([1 3e4+1 -10*cutoff 10*cutoff])
                else
                    %if no song, plot flatline
                    plot([1 2],[0 0],'k')
                    axis([1 2 -10*cutoff 10*cutoff])
                end
                
            end
            axis off
            
            
        end
        
    else
        for i = 1:ncolumns+1
            %could not extract noise, take ncolumns loud bits
            signal = find(song > 3 * std(song));
            if numel(signal) >= ncolumns;
                samples = randsample(signal,ncolumns);
                rep = 0;
                while any(samples-2e4<0) || any(samples+2e4>length(song))%this is to ensure that plotted values are included in song
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
            
            plotnum = plotnum + 1;
            axes(ax(plotnum))
            if i == 1
                row = sprintf(['Channel ' num2str(y) ':Error\nCould not extract noise.']);
                text(0,.5,row,'FontSize',10);
            else
                if samples(i-1) ~= 0;
                    plot(1:3e4+1,song(samples(i-1) - 1.5e4:samples(i-1) + 1.5e4),'k')
                    axis([1 3e4+1 -10*cutoff 10*cutoff])
                else
                    %if no song, plot flatline
                    plot([1 2],[0 0],'k')
                    axis([1 2 -10*cutoff 10*cutoff])
                end
            end
            axis off
            
            
        end
    end
    
    clear xempty
    
end

if isOpen == -1%if pool opened in this script, then close
    if poolavail~=0
        matlabpool close force local
    end
end

fprintf('Saving figure.\n')
[pathstr, name, ~] = fileparts(daqfile);
if nchannels ~= length(daqinfo.ObjInfo.Channel);
    fileName_channels = sprintf('_%d',channels);
    outfile = [pathstr filesep name '_ch' fileName_channels '.png'];
else
    outfile = [pathstr filesep name '.png'];
end
warning('off','MATLAB:LargeImage')
export_fig(outfile,'-r300');
close(h);
    