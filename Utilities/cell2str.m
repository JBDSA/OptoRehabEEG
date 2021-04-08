function [ str ] = cell2str(cell, delimiter)
% Convert the content of a cell to a string where each cell is separated by the delimiter
% supports numeric and string cells
%
% Author: Alexandre Delaux, 2020

str= '';
for c=1:numel(cell)
    if ischar(cell{c})
        str = [str cell{c} delimiter];
    end
    if isscalar(cell{c})
        str = [str num2str(cell{c}) delimiter];
    end
end
str = str(1:end-1); % remove the last delimiter
end

