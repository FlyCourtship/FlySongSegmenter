function [strainNames strainInitials] = extractStrainNames(file_names)
%USAGE [strainNames strainInitials] = extractStrainNames(file_names)
f = file_names;
numf = numel(f);
strainNames = cell(numf,1);
strainInitials = cell(numf,1);
for i = 1:numf
    r=regexp(f(i),'_','split');
    name = r{1}(1);
    strainNames{i} = char(name);
    strainInitials{i} = strainNames{i}(1);
end
strainInitials= cell2mat(strainInitials);
