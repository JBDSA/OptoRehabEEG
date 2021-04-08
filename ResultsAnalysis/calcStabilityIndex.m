function [Feats, AppearanceRate, StabilityIndex] = calcStabilityIndex(classifierInfo, features2test)
% Compute the appearance rate of features across folds, depending on the
% number of features selected by the classifier. Compute a stability index
% based on the general stability of feature selection
%
% Author: Alexandre Delaux, 2020

Feats = cell(length(features2test),1);
AppearanceRate = cell(length(features2test),1);
StabilityIndex = nan(length(features2test),1);
for Nfeat = 1:length(features2test)
    all_folds = classifierInfo.Nb_feat == features2test(Nfeat);
    FeaturesSelected = classifierInfo.Sel_feats(all_folds);
    all_feats = unique(cell2mat(FeaturesSelected));
    count_feats = zeros(length(all_feats),1);
    for f = 1:numel(FeaturesSelected)
        [~,~,inds] = intersect(FeaturesSelected{f},all_feats);
        count_feats(inds)= count_feats(inds)+1;
    end
    Feats{Nfeat} = all_feats;
    AppearanceRate{Nfeat} = 100*count_feats./numel(FeaturesSelected);
    
    temp = sort(AppearanceRate{Nfeat},'descend');
    StabilityIndex(Nfeat) = mean(temp(1:features2test(Nfeat)));
end
end