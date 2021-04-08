function saveCurrentFig(filepath, filename, formats, size4png)
% Save current figure in multiple formats (mainly designed for 'fig' and
% 'png' formats)
% Close the figure at the end
%
% Inputs:
% filepath      - where you want your file saved
% filename      - the name of your file (without extension)
% formats       - the list of formats in which to save (cell)
% size4png      - array for resizing the figure to the desired size for the
%                   png format ([hor vert] in pixels). leave it empty if you
%                   don't wish to modify the size
%
% Author: Alexandre Delaux, 2020

for f= 1:numel(formats)
    if strcmp(formats{f}, 'png') && ~isempty(size4png)
        set(gcf, 'Position', [50, 50, size4png(1), size4png(2)]);
    end
    saveas(gcf, [filepath, filename, '.', formats{f}], formats{f});
end
close(gcf)
end

