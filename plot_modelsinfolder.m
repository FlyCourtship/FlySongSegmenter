function plot_modelsinfolder(folder)
addpath(genpath('./export_fig'))
addpath(genpath('./tight_subplot'))

sep = filesep;
dir_list = dir(folder);
file_num = length(dir_list);

ncolumns = 8;
nrows = 4;
plotnum = 0;
clf;
figure('OuterPosition',[0 0 ncolumns*200 nrows*100]);
ax = tight_subplot(nrows,ncolumns,[.005 .01],[.01 .01],[.01 .01]);

plotnum = 0;

for y = 1:file_num
    file = dir_list(y).name; %pull out the file name
    [~,root,ext] = fileparts(file);
    path_file = [folder sep file];
    TG = strcmp(ext,'.mat');
    
    
    if TG == 1
        if strfind(root,'pm') ~= 0
            plotnum = plotnum + 1;
            axes(ax(plotnum));
            
            %get plot data and limits
            load(path_file,'pulse_model');
            right = size(pulse_model.fhM,2); 
            bottom_value = min(min(pulse_model.fhZ));
            top_value =  max(max(pulse_model.fhZ));
            bottom = bottom_value - std(min(pulse_model.fhZ));
            top = top_value + std(max(pulse_model.fhZ));
            parsed_filename = textscan(root,'%s','Delimiter','_');
            ch = strcat(parsed_filename{1}(2),parsed_filename{1}(3));
            
            if numel(pulse_model.fhM) >0
                %plot data
                hold on
                axis([1 right bottom top])
                plot(pulse_model.fhZ','g');
                plot(pulse_model.fhM,'k');
                text(1,bottom+ std(min(pulse_model.fhZ)),ch,'FontSize',10);
                hold off
            end
        end
    end
end
[pathstr,name,~]=fileparts(folder);
outfile = [pathstr name '_pulsemodels.png'];
warning('off','MATLAB:LargeImage');
export_fig(outfile,'-r300');