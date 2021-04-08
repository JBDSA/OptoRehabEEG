% Author: Alexandre Delaux, 2020

clear
close all

%% First classifier:
% Object vs Non-object trials in the stimulation condition
for pipe = 5:5
    user = 'Alex';
    freqs = 1:40;
    pipeline_ind = pipe;
    normStyle = 'perFeat';
    createFeatures1;
    
    % Principal parameters for the classifier
    models = {'linear'};
    for c = 1:numel(models)
        for sel = 1:3
            switch sel
                case 1
                    feat_sel_name = 'AllChannels_1-40Hz';
                    chan_sel = 'all';
                    freq_sel = 'all';
                case 2
                    feat_sel_name = 'AllChannels_Alpha';
                    chan_sel = 'all';
                    freq_sel = [8,12];
                case 3
                    feat_sel_name = 'OccChannels_Alpha';
                    chan_sel = {'Oz', 'O1', 'O2'};
                    freq_sel = [8,14];
            end
            
            classifierModel = models{c};
            features2test = [1:6];
            nb_folds = 5:5:20;
            
            runClassifier;
        end
    end
    clear
    close all
end

%% Second classifier:
% Object vs Non-object trials in the Natural Monoc condition
for p = 5:5
    user = 'Alex';
    freqs = 1:40;
    pipeline_ind = p;
    normStyle = 'perFeat';
    createFeatures2;
    
    % Principal parameters for the classifier
    models = {'linear'};
    for c = 1:numel(models)
        for sel = 1:3
            switch sel
                case 1
                    feat_sel_name = 'AllChannels_1-40Hz';
                    chan_sel = 'all';
                    freq_sel = 'all';
                case 2
                    feat_sel_name = 'AllChannels_Alpha';
                    chan_sel = 'all';
                    freq_sel = [8,12];
                case 3
                    feat_sel_name = 'OccChannels_Alpha';
                    chan_sel = {'Oz', 'O1', 'O2'};
                    freq_sel = [8,14];
            end
            classifierModel = models{c};
            features2test = [1:6];
            nb_folds = 5:5:20;
            
            % Same file for both classifiers
            runClassifier;
        end
    end
    clear
    close all
end

%% Third classifier:
% Object vs Non-object trials in the Natural Binoc condition
for p = 5:5
    user = 'Alex';
    freqs = 1:40;
    pipeline_ind = p;
    normStyle = 'perFeat';
    createFeatures3;
    
    % Principal parameters for the classifier
    models = {'linear'};
    for c = 1:numel(models)
        for sel = 1:3
            switch sel
                case 1
                    feat_sel_name = 'AllChannels_1-40Hz';
                    chan_sel = 'all';
                    freq_sel = 'all';
                case 2
                    feat_sel_name = 'AllChannels_Alpha';
                    chan_sel = 'all';
                    freq_sel = [8,12];
                case 3
                    feat_sel_name = 'OccChannels_Alpha';
                    chan_sel = {'Oz', 'O1', 'O2'};
                    freq_sel = [8,14];
            end
            classifierModel = models{c};
            features2test = [1:6];
            nb_folds = 5:5:20;
            
            % Same file for both classifiers
            runClassifier;
        end
    end
    clear
    close all
end
