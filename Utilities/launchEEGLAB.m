% Author: Alexandre Delaux, 2020

path= 'C:\Program Files\MATLAB\R2019a\toolbox\matlab\graph2d';
%rmpath(path)
addpath(genpath(path), '-begin')
% Should return 'C:\Program Files\MATLAB\R2019a\toolbox\matlab\graph2d\axis.p
which axis

% Commands:
eeglab;
pop_editoptions('option_storedisk', 1, 'option_savetwofiles', 1,...
    'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0,...
    'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1,...
    'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 0, 'option_chat', 0);