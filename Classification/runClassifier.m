% Author: Alexandre Delaux, 2020

saving_folder = [config.studyFolder, feat_sel_name, filesep];
if ~isfolder(saving_folder)
    mkdir(saving_folder)
end

%%%%%%%%%%%%%%%%%%%%%% EYES CLOSED %%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('EYES CLOSED');
%% Convert to Features
disp('Selecting Features');
[Features_EC, chan_labels, freq_labels] = select_features(Power_all_EC,chan_sel,EEG.chanlocs,freq_sel);
nb_trials = size(Features_EC,2);
%% Fisher score to get the most discriminative features
disp('Fisher Analysis')
[OrderInd, scoreOfFeatures] = rankfeat(Features_EC', Labels_all_EC, 'fisher');
max_feat='all';
visualize_Fischer(OrderInd,scoreOfFeatures,max_feat,chan_labels,freq_labels);
saveCurrentFig(saving_folder, 'FischerScore_allFeatures-EC', {'png'}, [1000,1000])
max_feat=features2test(end);
visualize_Fischer(OrderInd,scoreOfFeatures,max_feat,chan_labels,freq_labels);
saveCurrentFig(saving_folder, ['FischerScore_',num2str(max_feat),'bestFeatures-EC'], {'png'}, [1000,1000])

%% Classification
disp('Classification')
for f = 1:length(nb_folds)+1
    if f == length(nb_folds)+1
        partition = cvpartition(nb_trials, 'LeaveOut');
        disp('Leave-one-out design')
    else
        partition = cvpartition(Labels_all_EC, 'kfold', nb_folds(f));
        fprintf('%d folds design\n',nb_folds(f))
    end
    [TrainingRes, TestingRes, classifierInfo] = optimizationCV(Features_EC', Labels_all_EC, partition, 'fisher', features2test, classifierModel);
    
    %Random classification level:
    random_predict = rand(nb_trials,1000);
    random_predict(random_predict<=0.5) = -1;
    random_predict(random_predict>0.5) = 1;
    RandomRes =struct();
    RandomRes.True_labels = Labels_all_EC;
    RandomRes.Scores = random_predict;
    
    CVstats= computeCVStatistic(TrainingRes, TestingRes, RandomRes, features2test);
    if f == length(nb_folds)+1
        saving_params = struct('model', classifierModel,'CV','LOO','folder', saving_folder,...
            'error', true, 'errorBal', false, 'AUC', false, 'CM', true);
    else
        saving_params = struct('model', classifierModel,'CV','folds','folder', saving_folder,...
            'error', true, 'errorBal', true, 'AUC', true, 'CM', true);
    end
    saving_params.classes = {'NoObject', 'Object'};
    saving_params.suffix = '-EC';
    plotCVstats(CVstats,features2test, saving_params);
    
    if f == length(nb_folds)+1
        save([saving_folder, classifierModel, '_results_LOO-EC'],'TrainingRes', 'TestingRes', 'classifierInfo','CVstats')
    else
        save([saving_folder, classifierModel, '_results_',num2str(nb_folds(f)),'folds-EC'],'TrainingRes', 'TestingRes', 'classifierInfo','CVstats')
    end
end

%%%%%%%%%%%%%%%%%%%%%% EYES OPEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('EYES OPEN');
%% Convert to Features
disp('Selecting Features');
[Features_EO, ~, ~] = select_features(Power_all_EO,chan_sel,EEG.chanlocs,freq_sel);
nb_trials = size(Features_EO,2);
%% Fisher score to get the most discriminative features
disp('Fisher Analysis')
[OrderInd, scoreOfFeatures] = rankfeat(Features_EO', Labels_all_EO, 'fisher');
max_feat='all';
visualize_Fischer(OrderInd,scoreOfFeatures,max_feat,chan_labels,freq_labels);
saveCurrentFig(saving_folder, 'FischerScore_allFeatures-EO', {'fig', 'svg', 'png'}, [1200,1200])
max_feat=features2test(end);
visualize_Fischer(OrderInd,scoreOfFeatures,max_feat,chan_labels,freq_labels);
saveCurrentFig(saving_folder, ['FischerScore_',num2str(max_feat),'bestFeatures-EO'], {'png'}, [1000,1000])

%% Classification
disp('Classification')
for f = 1:length(nb_folds)+1
    if f == length(nb_folds)+1
        partition = cvpartition(nb_trials, 'LeaveOut');
        disp('Leave-one-out design')
    else
        partition = cvpartition(Labels_all_EO, 'kfold', nb_folds(f));
        fprintf('%d folds design\n',nb_folds(f))
    end
    [TrainingRes, TestingRes, classifierInfo] = optimizationCV(Features_EO', Labels_all_EO, partition, 'fisher', features2test, classifierModel);
    
    %Random classification level:
    random_predict = rand(nb_trials,1000);
    random_predict(random_predict<=0.5) = -1;
    random_predict(random_predict>0.5) = 1;
    RandomRes =struct();
    RandomRes.True_labels = Labels_all_EO;
    RandomRes.Scores = random_predict;
    
    CVstats= computeCVStatistic(TrainingRes, TestingRes, RandomRes, features2test);
    if f == length(nb_folds)+1
        saving_params = struct('model', classifierModel,'CV','LOO','folder', saving_folder,...
            'error', true, 'errorBal', false, 'AUC', false, 'CM', true);
    else
        saving_params = struct('model', classifierModel,'CV','folds','folder', saving_folder,...
            'error', true, 'errorBal', true, 'AUC', true, 'CM', false);
    end
    saving_params.classes = {'NoObject', 'Object'};
    saving_params.suffix = '-EO';
    plotCVstats(CVstats,features2test, saving_params);
    
    if f == length(nb_folds)+1
        save([saving_folder, classifierModel, '_results_LOO-EO'],'TrainingRes', 'TestingRes', 'classifierInfo','CVstats')
    else
        save([saving_folder, classifierModel, '_results_',num2str(nb_folds(f)),'folds-EO'],'TrainingRes', 'TestingRes', 'classifierInfo','CVstats')
    end
end