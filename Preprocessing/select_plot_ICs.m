function [ALLEEG, EEG, CURRENTSET, ICs2keep, ICs2throw, ICsbrain] = select_plot_ICs(EEG, ALLEEG, CURRENTSET, classes2keep, method, save_path_figs, subject_id, out_filename, out_filepath)
% Cleans data with the help of the ICLabel classifications (computed previously).
% Plots kept and thrown ICs according to their respective summed score (or 1 - said score).
% The classes are: {'Brain'  'Muscle'  'Eye'  'Heart'  'Line Noise'  'Channel Noise'  'Other'}
%
% Usage:
%   >> [ALLEEG, EEG, CURRENTSET, ICs2keep, ICs2throw, ICsbrain] = bemobil_clean_with_iclabel(EEG, ALLEEG, CURRENTSET, classes2keep, method)
%   >> [ALLEEG, EEG, CURRENTSET, ICs2keep, ICs2throw, ICsbrain] = bemobil_clean_with_iclabel(EEG, ALLEEG, CURRENTSET, classes2keep, method, save_path_figs, subject, out_filename, out_filepath)
%
% Inputs:
%   ALLEEG                  - complete EEGLAB data set structure
%   EEG                     - current EEGLAB EEG structure
%   CURRENTSET              - index of current EEGLAB EEG structure within ALLEEG
%   classes_to_keep         - indices of the classes to be kept in the data (e.g. [1 7] for brain and other)
%   method                  - method used to select ICs (dependent on the output of IC_categorization)
%                               ['mostProbable' 'user' 'eligible']
%   save_path_figs          - (optional) save path for figures
%   subject_id              - (optional) [string] subject ID for figure names
%   out_filename            - (optional) output filename
%   out_filepath            - (optional) output filepath - File will only be saved on disk
%                               if both a name and a path are provided
%
% Outputs:
%   ALLEEG                  - complete EEGLAB data set structure
%   EEG                     - current EEGLAB EEG structure
%   Currentset              - index of current EEGLAB EEG structure within ALLEEG
%   ICs2keep                - indices of the ICs to keep
%   ICs2throw               - indices of the ICs to reject
%   ICsbrain                - indices of the brain ICs (empty if Brain is not in ICs2keep)
%
%   .set data file of current EEGLAB EEG structure stored on disk (OPTIONALLY)
%
% See also:
%   EEGLAB, pop_iclabel, bemobil_plot_patterns
%
% Author: Alexandre Delaux, 2020

% only save a file on disk if both a name and a path are provided
save_file_on_disk = (exist('out_filename', 'var') && exist('out_filepath', 'var'));

% check if file already exist and % classes: {'Brain'  'Muscle'  'Eye'  'Heart'  'Line Noise'  'Channel Noise'  'Other'}show warning if it does
if save_file_on_disk
    mkdir(out_filepath); % make sure that folder exists, nothing happens if so
    dir_files = dir(out_filepath);
    if ismember(out_filename, {dir_files.name})
        warning([out_filename ' file already exists in: ' out_filepath '. File will be overwritten...']);
    end
end

classes = {'Brain'  'Muscle'  'Eye'  'Heart'  'Line Noise'  'Channel Noise'  'Other'};
classifications = EEG.etc.ic_classification.ICLabel.classifications;
thresholds = EEG.etc.ic_classification.ICLabel.detectionThresholds;
mostProbableClass = EEG.etc.ic_classification.ICLabel.mostProbableClass;
eligible_classes = EEG.etc.ic_classification.ICLabel.eligibleClasses; % ordered from the most to the least probable
userSelectedClass = EEG.etc.ic_classification.ICLabel.userSelectedClass;

%% ICs to accept:
MainTitle_keep = ['Kept classes: ' cell2str(classes(classes2keep), ' ')];
ICs2keep = [];
ICsbrain = [];
summedScores2keep = zeros(size(classifications,1),1);
IClabels = cell(size(classifications,1),1);

for c = 1:7
    
    switch method
        case 'mostProbable'
            newICs = find(mostProbableClass == c)';
        case 'user'
            newICs = find(userSelectedClass == c)';
        case 'eligible'
            newICs = find(sum(eligible_classes == c,2))';
        otherwise
            error('Method not recognized');
    end
    
    if c==1
        ICsbrain = newICs';
    end
    
    for IC = newICs
        if find(classes2keep==c)
            summedScores2keep(IC) = summedScores2keep(IC) + classifications(IC, c);
        end
        
        if isempty(IClabels{IC})
            IClabels{IC} = [num2str(IC) ': ' classes{c}];
        else
            IClabels{IC} = [IClabels{IC} classes{c}];
        end
    end
    
    if find(classes2keep==c)
        ICs2keep = union(ICs2keep, newICs);
    end
end

% Plot the activation pattern for each IC
threshold_fig = max(thresholds(classes2keep));
MainTitle_keep = [MainTitle_keep, ', Threshold: ', num2str(threshold_fig)];
maxICs_per_plot = 16;
n_plots = ceil(length(ICs2keep)/maxICs_per_plot);
for p = 1:n_plots
    ICs2plot = ICs2keep((p-1)*maxICs_per_plot+1:min(p*maxICs_per_plot, length(ICs2keep)));
    scores = summedScores2keep; % temp for plotting
    scores(setdiff(1:size(classifications,1), ICs2plot)) = 0;
    fig = bemobil_plot_patterns(EEG.icawinv, EEG.chanlocs,...
        'weights',scores,'minweight',threshold_fig, 'titles', IClabels);
    suptitle(MainTitle_keep);
    if exist('save_path_figs','var')
        if length(ICs2plot)>2
            saveCurrentFig(save_path_figs, [subject_id '_ICs_kept_' method '_' num2str(p)], {'png'}, [900 900])
        else
            saveCurrentFig(save_path_figs, [subject_id '_ICs_kept_' method '_' num2str(p)], {'fig'}, [])
        end
    end
end

%% ICs not retained:
ICs2throw = setdiff(1:size(classifications,1), ICs2keep)';

%% Clean the data (remove ICs to throw) and update the struct
EEG_clean = pop_subcomp(EEG, ICs2throw);

EEG_clean.etc.ic_cleaning.method = method;
EEG_clean.etc.ic_cleaning.keptClasses = classes2keep;
EEG_clean.etc.ic_cleaning.usedThresholds = thresholds;
EEG_clean.etc.ic_cleaning.summedScores_keptICs = summedScores2keep;
EEG_clean.etc.ic_cleaning.keptICs = ICs2keep;
EEG_clean.etc.ic_cleaning.assignedLabels = IClabels;
EEG_clean.etc.ic_cleaning.thrownICs = ICs2throw;

%% new data set in EEGLAB
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG_clean, CURRENTSET, 'gui', 'off');
EEG = eeg_checkset( EEG );

% save on disk
if save_file_on_disk
    EEG = pop_saveset( EEG, 'filename', out_filename,'filepath', out_filepath);
    disp('...done');
end
end