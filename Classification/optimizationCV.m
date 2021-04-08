function [Training, Testing, classifierInfo] = optimizationCV(features, labels, partition, orderMethod, features2test, model)
% Performs CV based on the given partition and the features presented.
% Fisher score ranking is used to gradually select the best features
%
% Author: Alexandre Delaux, 2020

nb_folds = partition.NumTestSets;
len_feat=length(features2test);
trainingLabelTrue = cell(len_feat, nb_folds);
trainingPredictionScores = cell(len_feat, nb_folds);

testLabelTrue = cell(len_feat, nb_folds);
testPredictionScores = cell(len_feat, nb_folds);

%For Storing classifier infos
Nb_feat=reshape(repmat(features2test, [nb_folds,1]),[len_feat*nb_folds,1]);
Fold=repmat([1:nb_folds]', [len_feat, 1]);
Sel_feats=cell(len_feat*nb_folds,1);
Gamma=zeros(len_feat*nb_folds,1);
Delta=zeros(len_feat*nb_folds,1);

for i=1:len_feat
    feat=features2test(i);
    disp(['number of selected features:' , num2str(feat)])
    
    for fold=1:nb_folds
        % subfolds
        trainingData = features(partition.training(fold), :);
        trainingLabels = labels(partition.training(fold));
        
        testData = features(partition.test(fold), :);
        testLabels = labels(partition.test(fold));
        
        % Fisher score for this training set
        [OrderInd, ~] = rankfeat(trainingData, trainingLabels, orderMethod);
        Selected_feat=OrderInd(1:feat);
        Sel_feats{nb_folds*(i-1)+fold}=Selected_feat;
        
        trainingData_red = trainingData(:, Selected_feat);
        testData_red = testData(:, Selected_feat);
        
        % training
        switch model
            case {'svm', 'logistic'}
                classifier = fitclinear(trainingData_red, trainingLabels, 'Learner', model);
                % prediction
                [~, trainingScores] = predict(classifier, trainingData_red);
                [~, testScores] = predict(classifier, testData_red);
            case {'linear', 'diaglinear'}
                Options.MaxObjectiveEvaluations=20;
                Options.ShowPlots=false;
                classifier = fitcdiscr(trainingData_red, trainingLabels, 'DiscrimType', model);
                % prediction
                [~, trainingScores] = predict(classifier, trainingData_red);
                [~, testScores] = predict(classifier, testData_red);
                Gamma(nb_folds*(i-1)+fold)=classifier.Gamma;
                Delta(nb_folds*(i-1)+fold)=classifier.Delta;
        end
        
        % store
        trainingLabelTrue{i,fold} = trainingLabels;
        trainingPredictionScores{i, fold} = trainingScores;
        testLabelTrue{i, fold} = testLabels;
        testPredictionScores{i, fold} = testScores;
    end
end

Training.True_labels=trainingLabelTrue;
Training.Scores=trainingPredictionScores;

Testing.True_labels=testLabelTrue;
Testing.Scores=testPredictionScores;

classifierInfo=table(Nb_feat, Fold, Sel_feats, Gamma, Delta);
end

