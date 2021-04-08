function statsCV = computeCVStatistic(TrainingRes, TestingRes, RandomRes, features2test)
% From the results of the classification across CV partition, computes
% various statistical indicators to indicate performance for the tested
% parameters (here only the number of features to select)
%
% Author: Alexandre Delaux, 2020

n_reps = size(RandomRes.Scores,2);
nb_folds = size(TrainingRes.Scores,2);
numberOfPointsInROC = 100;

len_feat=length(features2test);
Random_Err = nan(1,n_reps);
Random_Err_bal = nan(1,n_reps);
Train_Err = nan(len_feat, nb_folds);
Train_Err_bal = nan(len_feat, nb_folds);
Test_Err = nan(len_feat, nb_folds);
Test_Err_bal = nan(len_feat, nb_folds);

Random_CM = nan(n_reps, 2, 2);
Train_CM = nan(len_feat, nb_folds, 2, 2);
Test_CM = nan(len_feat, nb_folds, 2, 2);

Random_AUC = nan(1,n_reps);
Train_ROC= cell(len_feat, nb_folds);
Train_AUC = nan(len_feat, nb_folds);
Test_ROC= cell(len_feat, nb_folds);
Test_AUC = nan(len_feat, nb_folds);

%% Random levels
for rep = 1:n_reps
    [Random_Err(rep),Random_CM(rep,:,:),~,percentages] = confusion(...
        cat(1,~RandomRes.True_labels',RandomRes.True_labels'),cat(1,-RandomRes.Scores(:,rep)',RandomRes.Scores(:,rep)'));
    Random_Err_bal(rep)=mean(percentages(2,1:2));
    
    [tpr,fpr,~] = roc(cat(1,~RandomRes.True_labels',RandomRes.True_labels'),cat(1,-RandomRes.Scores(:,rep)',RandomRes.Scores(:,rep)'));
    % AUC calculation
    Random_AUC(rep)=AUC_manual(fpr{2}, tpr{2});
end
Random_Err = mean(Random_Err);
Random_Err_bal = mean(Random_Err_bal);
Random_AUC = mean(Random_AUC);

for i=1:len_feat
    for fold=1:nb_folds
        %% Training
        [Train_Err(i,fold),Train_CM(i,fold,:,:),~,percentages] = confusion(...
            cat(1,~TrainingRes.True_labels{i,fold}',TrainingRes.True_labels{i,fold}'),TrainingRes.Scores{i,fold}');
        Train_Err_bal(i,fold)=mean(percentages(2,1:2));
        
        [tpr,fpr,~] = roc(...
            cat(1,~TrainingRes.True_labels{i,fold}',TrainingRes.True_labels{i,fold}'),TrainingRes.Scores{i,fold}');
        % Uniformize ROC calculation
        [Train_ROC{i,fold}.fpr, Train_ROC{i,fold}.tpr]=uniform_ROC(fpr{2}, tpr{2}, numberOfPointsInROC);
        % AUC calculation
        Train_AUC(i,fold)=AUC_manual(fpr{2}, tpr{2});
        
        %% Testing
        [Test_Err(i,fold),Test_CM(i,fold,:,:),~,percentages] = confusion(...
            cat(1,~TestingRes.True_labels{i,fold}',TestingRes.True_labels{i,fold}'),TestingRes.Scores{i,fold}');
        Test_Err_bal(i,fold)=mean(percentages(2,1:2));
        
        [tpr,fpr,~] = roc(...
            cat(1,~TestingRes.True_labels{i,fold}',TestingRes.True_labels{i,fold}'),TestingRes.Scores{i,fold}');
        % Uniformize ROC calculation
        [Test_ROC{i,fold}.fpr, Test_ROC{i,fold}.tpr]=uniform_ROC(fpr{2}, tpr{2}, numberOfPointsInROC);
               % AUC calculation
        Test_AUC(i,fold)=AUC_manual(fpr{2}, tpr{2});
    end
end

%% output
statsCV.random.Err = Random_Err;
statsCV.random.Err_bal = Random_Err_bal;
statsCV.random.AUC = Random_AUC;

statsCV.training.Err = Train_Err;
statsCV.training.Err_bal = Train_Err_bal;
statsCV.training.CM = Train_CM;
statsCV.training.ROCs = Train_ROC;
statsCV.training.AUC = Train_AUC;

statsCV.testing.Err = Test_Err;
statsCV.testing.Err_bal = Test_Err_bal;
statsCV.testing.CM = Test_CM;
statsCV.testing.ROCs = Test_ROC;
statsCV.testing.AUC = Test_AUC;
end
