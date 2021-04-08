% Author: Alexandre Delaux, 2020

clear
close all

user = 'Alex';
freqs = 1:40;

% Comparison between classifiers:
classifiers = [1,2,3];
classes_names = {'Stimulation-EO', 'Stimulation-EC', 'Natural Monoc-EO', 'Natural Monoc-EC', 'Natural Binoc-EO', 'Natural Binoc-EC'};
save_folderName = 'ForPaper_main';
nb_folds = 5:5:20;
features2test = 1:6;
sels = [5];

for fold = 1:length(nb_folds)+1
    for p = 5:5
        pipeline_ind = p;
        %normStyle = 'acrossChans';
        normStyle = 'perFeat';
        
        if ~exist('EEG', 'var')
            switch user
                case 'Alex'
                    launchEEGLAB
                case 'JB'
                    eeglab
            end
        end
        
        % Principal parameters for the classifier
        feat_sel_name = 'OccChannels_Alpha';
        chan_sel = {'Oz', 'O1', 'O2'};
        freq_sel = [8,14];
        classifierModel = 'linear';
        
        if fold < length(nb_folds)+1
            TestingErrAll = zeros(length(features2test), nb_folds(fold), 2*numel(classifiers));
        end
        TestingErrAve = zeros(length(features2test), 2*numel(classifiers));
        TrainingErrAve = zeros(length(features2test), 2*numel(classifiers));
        TestingErrSE = zeros(length(features2test), 2*numel(classifiers));
        TrainingErrSE = zeros(length(features2test), 2*numel(classifiers));
        for c = 1:numel(classifiers)
            classifier = classifiers(c);
            config = config_classifier(user,pipeline_ind,normStyle,classifier);
            saving_folder = [config.studyFolder, feat_sel_name, filesep];
            
            if fold == length(nb_folds)+1
                results_EO{c} = load([saving_folder, classifierModel, '_results_LOO-EO']);
            else
                results_EO{c} = load([saving_folder, classifierModel, '_results_', num2str(nb_folds(fold)),'folds-EO']);
                TestingErrSE(:,2*c-1) = 100*std(results_EO{c}.CVstats.testing.Err,[],2)/sqrt(nb_folds(fold));
                TrainingErrSE(:,2*c-1) = 100*std(results_EO{c}.CVstats.training.Err,[],2)/sqrt(nb_folds(fold));
                % For statistical test
                TestingErrAll(:,:,2*c-1) = 100*results_EO{c}.CVstats.testing.Err;
            end
            % Average over all folds
            TestingErrAve(:,2*c-1) = 100*mean(results_EO{c}.CVstats.testing.Err,2);
            TrainingErrAve(:,2*c-1) = 100*mean(results_EO{c}.CVstats.training.Err,2);
            
            if fold == length(nb_folds)+1
                results_EC{c} = load([saving_folder, classifierModel, '_results_LOO-EC']);
            else
                results_EC{c} = load([saving_folder, classifierModel, '_results_', num2str(nb_folds(fold)),'folds-EC']);
                TestingErrSE(:,2*c) = 100*std(results_EC{c}.CVstats.testing.Err,[],2)/sqrt(nb_folds(fold));
                TrainingErrSE(:,2*c) = 100*std(results_EC{c}.CVstats.training.Err,[],2)/sqrt(nb_folds(fold));
                % For statistical test
                TestingErrAll(:,:,2*c) = 100*results_EC{c}.CVstats.testing.Err;
            end
            % Average over all folds
            TestingErrAve(:,2*c) = 100*mean(results_EC{c}.CVstats.testing.Err,2);
            TrainingErrAve(:,2*c) = 100*mean(results_EC{c}.CVstats.training.Err,2);
        end
        
        Errors = zeros(size(TestingErrAve,2),2);
        SEs = zeros(size(TestingErrAve,2),2);
        if fold < length(nb_folds)+1
            All_samples = zeros(size(TestingErrAve,2),nb_folds(fold));
        end
        optNfeats = zeros(1,size(TestingErrAve,2));
        figure
        for col = 1:size(TestingErrAve,2)
            [optTestErr, optNfeats(col)] = min(TestingErrAve(:,col));
            Errors(col,:) = [TrainingErrAve(optNfeats(col),col), optTestErr];
            SEs(col,:) = [TrainingErrSE(optNfeats(col),col), TestingErrSE(optNfeats(col),col)];
            if fold < length(nb_folds)+1
                All_samples(col,:) = TestingErrAll(optNfeats(col),:,col);
            end
            
            if mod(col,2)==1
                [Feats, AppearanceRate, ~] = calcStabilityIndex(results_EO{ceil(col/2)}.classifierInfo,features2test);
            else
                [Feats, AppearanceRate, ~] = calcStabilityIndex(results_EC{ceil(col/2)}.classifierInfo,features2test);
            end
            figName = classes_names{col};
            
            freq_vect = freq_sel(1):freq_sel(2);
            n_feats = length(Feats{optNfeats(col)});
            featNames = cell(n_feats,1);
            for f = 1:n_feats
                if mod(Feats{optNfeats(col)}(f),numel(chan_sel)) == 0
                    featNames{f} = [chan_sel{end},'-'];
                else
                    featNames{f} = [chan_sel{mod(Feats{optNfeats(col)}(f),numel(chan_sel))},'-'];
                end
                
                featNames{f} = [featNames{f},...
                    num2str(freq_vect(ceil(Feats{optNfeats(col)}(f)/numel(chan_sel)))), 'Hz'];
            end
            
            subplot(size(TestingErrAve,2)/2,2,col)
            bar(AppearanceRate{optNfeats(col)})
            xticks(1:n_feats)
            xticklabels(featNames)
            xtickangle(45)
            ylim([0,100])
            ylabel('Frequency of appearance across folds (%)')
            if optNfeats(col) == 1
                title([figName, ' (1 feature)'])
            else
                title([figName, ' (', num2str(optNfeats(col)), ' features)'])
            end
        end
        
        if fold == length(nb_folds)+1
            suptitle('LOO - Features contribution to the optimal classification accuracy')
            saveCurrentFig([config.workingFolder, 'ClassifierResults', filesep,'NormPerFeat' filesep, save_folderName, filesep],...
                ['Features_appearance_LOO'], {'fig', 'svg', 'png'}, [1000,800])
        else
            suptitle([num2str(nb_folds(fold)),'folds - Features contribution to the optimal classification accuracy'])
            saveCurrentFig([config.workingFolder, 'ClassifierResults', filesep,'NormPerFeat' filesep, save_folderName, filesep],...
                ['Features_appearance_', num2str(nb_folds(fold)),'folds'], {'fig', 'svg', 'png'}, [1000,800])
        end
        
        %% Unstacked Accuracy
        data2plot = 100 - Errors;
        All_samples = 100 - All_samples;
        
        figure
        hold on
        bar(data2plot(:,2))
        if fold < length(nb_folds)+1
            errorbar(1:size(data2plot,1), data2plot(:,2), SEs(:,2),...
                'k','LineStyle','none')
        end
        yline(50, 'k--');
        xticks(1:size(TestingErrAve,2))
        xticklabels(classes_names)
        xtickangle(45)
        ylabel('Mean classification accuracy across folds (%)')
        ylim([0,100])
        if fold == length(nb_folds)+1
            legend({'Mean Testing', 'Chance level'})
            title(['LOO - Classification accuracy achieved for the optimal number of features per condition'])
            saveCurrentFig([config.workingFolder, 'ClassifierResults', filesep,'NormPerFeat' filesep, save_folderName, filesep],...
                ['barplot_acc_unstacked_', feat_sel_name, '_LOO'], {'fig', 'svg', 'png'}, [1000,800])
        else
            legend({'Mean Testing', 'SE', 'Chance level'})
            title([num2str(nb_folds(fold)), 'folds - Classification accuracy achieved for the optimal number of features per condition'])
            saveCurrentFig([config.workingFolder, 'ClassifierResults', filesep,'NormPerFeat' filesep, save_folderName, filesep],...
                ['barplot_acc_unstacked_', feat_sel_name, '_', num2str(nb_folds(fold)),'folds'], {'fig', 'svg', 'png'}, [1000,800])
        end
    end
end