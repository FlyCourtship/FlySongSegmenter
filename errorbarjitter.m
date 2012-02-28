function errorbarjitter(d, offset, mean_or_med,...
    sort_or_nosort, colheaders, factor,left_or_right,barends)
%USAGE errorbarjitter(d, offset, mean_or_med,sort_or_nosort, colheaders, factor,left_or_right,barends)
%Plots mean (or median)±SD plus jitter plot of raw data
%Columns are categories, rows are individual samples.
%From command line, user can:
%1 - control of offset of plotted statistics and raw data from each other. 
%2 - determine whether mean or median is plotted
%3 - determine whether categories are sorted (low to high) by mean values
%4 - determine whether X axis labels (colheaders) are shown
%
%PLOT_U_SD_JITTERRAW(D) plots with default values and no x-axis labels.
%
%PLOT_U_SD_JITTERRAW(D,OFFSET) plots with user defined offset of mean±SD
%and jittered raw data
%
%PLOT_U_SD_JITTERRAW(D,OFFSET,MEAN_OR_MEDIAN) plot with user defined offset
%and either mean ('mean') or median ('median')
%
%PLOT_U_SD_JITTERRAW(D,OFFSET,MEAN_OR_MEDIAN, SORT_OR_NOSORT) plot with user defined offset
%and either mean ('mean') or median ('median') and either sorted data
%('sort') or user entered order ('nosort'). Default is nosort.
%
%PLOT_U_SD_JITTERRAW(D,[],[],SORT_OR_NOSORT,COLHEADERS) plot with user defined
%column headers. It is a bad idea to sort without providing colheaders,
%since it may not be easy to track the source of the data. 
%
%
%PLOT_U_SD_JITTERRAW(D,[],[],[],[],FACTOR) plot with user defined factor for
%scaling the jitter
%
%PLOT_U_SD_JITTERRAW(D,[],[],[],[],[],LEFT_OR_RIGHT) when LEFT_OR_RIGHT = 
%'left' plot with mean±SD line on left, when = 'right', plot with bar on 
%right (default)
%
%PLOT_U_SD_JITTERRAW(D,[],[],[],[],[],[],BARENDS) when barends = 'yes', plot with capped ends of SD
%bars, when = 'no' (default), plot without barends
%
%ACKNOWLEDGEMENT: This function depends on jitter.m, writtn by Richie
%Cotton.
%
%
% $	Author: David Stern	$   $   Date :2011/11/02   $

% Check number of inputs
if nargin < 1
    error('plot_u_sd_jitterraw:notEnoughInputs', 'This function requires at least one input.');
end
    
% Set defaults where required
if nargin < 2 || isempty(offset)
    offset = 0.2;
end

if nargin < 3 || isempty(mean_or_med)
    mean_or_med = 'mean';
end

if nargin < 4 || isempty(sort_or_nosort)
    sort_or_nosort = 'nosort';
end

if nargin <5 && strcmp(sort_or_nosort,'sort') ==1
    skip_colheaders = 1;
    fprintf('It is a bad idea to sort without providing colheaders.\n')
    fprintf('Good luck keeping track of your data!\n')
elseif strcmp(sort_or_nosort,'sort') ==1 && isempty(colheaders)
    skip_colheaders = 1;
    fprintf('It is a bad idea to sort without providing colheaders.\n')
    fprintf('Good luck keeping track of your data!\n')
    
end

if nargin<5 || isempty(colheaders) 
    skip_colheaders = 1;
else
    skip_colheaders = 0;
end

if nargin < 6 || isempty(factor)
    factor = 1;
end

if nargin < 7 || isempty(left_or_right)
    left_or_right = 'right';
elseif strcmp(left_or_right,'left') == 1
    offset = -offset;
end


if nargin < 8 || isempty(barends)
    barends = 'no';
end

if nargin < 9 || isempty(Xsep)
    Xsep = 1;
end

addpath('./jitter')

figure(1)
clf
hold on

n_categories = size(d,2);
n_data = size(d,1);
    

if strcmp(mean_or_med,'mean') == 1
    mean_d = nanmean(d);
elseif strcmp(mean_or_med,'median') == 1
    mean_d = nanmedian(d);
end


%add option to sort data by mean
%there must be an easier way to rearrange an array by a property of columns
if strcmp(sort_or_nosort,'sort') == 1
    sort_ind = zeros(1,n_categories);
    
    %sort by mean or median
    for x = 1:size(mean_d,2)
        sort_ind(x) = find(mean_d(x) == sort(mean_d));
    end

    %now put original array in new order
    %if data in colheaders, sort that one too
    %there must be an easy way to do this
    sorted_d=[];
    for i = 1:n_categories
        sorted_d(:,sort_ind(i)) = d(:,i);
    end
    d = sorted_d;
    if skip_colheaders ~= 1
        sorted_colheaders = {};
        for i = 1:n_categories
            sorted_d(:,sort_ind(i)) = d(:,i);
            sorted_colheaders{sort_ind(i)} = colheaders{i};
        end
        colheaders = sorted_colheaders;
    end
    %recalculate mean for newly sorted data
    if strcmp(mean_or_med,'mean') == 1
        mean_d = nanmean(d);
    elseif strcmp(mean_or_med,'median') == 1
        mean_d = nanmedian(d);
    end
end





%for column in data
%plot (mean ±SD)
e = nanstd(d,1);
%define X axis positions
x = 1:1:n_categories;
x = x*Xsep;

%put column indices in each column
    
%x = indices + offset
if strcmp(barends,'no') == 1
    scatter(x+offset,mean_d,[],'k','filled')
else
    errorbar(mean_d,e,'ok','MarkerFaceColor','k','XData',x+offset)
end
%plot error lines
for i = 1:n_categories
    line([x(i)+offset x(i)+offset],[mean_d(i)-e(i) mean_d(i)+e(i)],'Color','k','LineWidth',.5)
end
%plot raw data with jitter in x axis to left of each
x=repmat(x,n_data,1);
x = jitter(x,factor);
x(isnan(d)) = NaN;

%make new matrix of X positions
%Y = jitter(vector of indices - offset)
for i = 1:n_categories
    scatter(x(:,i)-offset,d(:,i),'MarkerEdgeColor','k')
end

if skip_colheaders == 0
    %add x axis labels
    set(gca,'XTick',[1:1:n_categories])
    set(gca,'XTickLabel',colheaders)
end
hold off