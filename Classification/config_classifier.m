function cfg = config_classifier(user, pipeline_ind, normStyle, classifier)
% Configuration file for the classifier
%
% Authors: Alexandre Delaux & Jean-Baptiste de Saint-Aubert, 2020

switch user
    case 'Alex'
        cfg.workingFolder = 'D:\OptoRehabEEG\Patient1001\';
    case 'JB'
        cfg.workingFolder = '/Users/jean-baptiste/Documents/DATA/Patient1001/';
end
cfg.days = {'2020-07-28','2020-07-29'};
cfg.conditions = {'Binoc-NoGlass', 'Monoc-NoGlass', 'Monoc-Glass'};
switch pipeline_ind
    case 1
        cfg.pipeline = 'Preprocessing1_noASR_SelectBlock';
    case 2
        cfg.pipeline = 'Preprocessing2_withASR_noSelect';
    case 3
        cfg.pipeline = 'Preprocessing3_noASR_SelectTrial';
    case 4
        cfg.pipeline = 'Preprocessing4_withASR_SelectTrial';
    case 5
        switch user
            case 'Alex'
                cfg.pipeline = 'Preprocessing5_noASR_SelectTrial_autoICs';
            case 'JB'
                cfg.pipeline = 'Preprocessing5_noASR_SelectTrial_buf1&4';
        end
    case 6
        switch user
            case 'Alex'
                cfg.pipeline = 'Preprocessing6_withASR_SelectTrial_autoICs';
            case 'JB'
                error('Not configured for JB!')
        end
        
    case 7
        switch user
            case 'Alex'
                cfg.pipeline = 'Preprocessing7_noASR_SelectTrial_manualICs';
            case 'JB'
                error('Not configured for JB!')
        end
    case 8
        switch user
            case 'Alex'
                cfg.pipeline = 'Preprocessing8_withASR_SelectTrial_manualICs';
            case 'JB'
                error('Not configured for JB!')
        end
    otherwise
        error('Unknown pipeline')
end
switch normStyle
    case 'acrossChans'
        cfg.studyFolder = [cfg.workingFolder, 'ClassifierResults',filesep,...
            'NormAcrossChans',filesep,'Classifier',num2str(classifier), filesep, cfg.pipeline, filesep];
    case 'perFeat'
        cfg.studyFolder = [cfg.workingFolder, 'ClassifierResults',filesep,...
            'NormPerFeat',filesep,'Classifier',num2str(classifier), filesep, cfg.pipeline, filesep];
    otherwise 
        error('Unknown Normalization style')
end

if ~isfolder(cfg.studyFolder)
    mkdir(cfg.studyFolder)
end
end