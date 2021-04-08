function [orderedInd, orderedPower] = rankfeat(data, label, method)
%This function evaluates discrimination power of features, using correlation
%coefficient, Fisher score, relief and infgain algorithms. Please check the
%slides or google it if you have any question about the detail of the
%algorithms. This function does not output selected features directly, but
%provide the evaluations of all features according to their contributions
%to the discrimination, using the algorithm you selected.
%
%Example: 
%   [orderedInd, orderedPower] = FeatureSel(data,label,'corr');
%
%Input:
%   data: This variable should be a two dimensional matrix, where each 
%         row is a sample and each colomn represents a feature.
%   method: This variable corresponds to specific feature selection methods, 
%         i.e. 'corr','fisher','relief' or 'infgain'. Choose one of them.
%   label: This variable should be a one dimensional matrix, which specifies 
%         label of data.
%
%Output:
%   orderedInd: Index of ordered features based on their relevancy
%   orderedPower: Sorted power of features
%
%
show = 0;
[nSample nFeature] = size(data);
switch method
    case 'corr'
        cor = zeros(1,nFeature);
        for iFeature =1 : nFeature
            cor(iFeature) = (corr(data(:,iFeature),label))^2;
        end
        if show
            plot(cor,'k','linewidth',2);
            xlabel('Feature','FontSize',18);ylabel('R^2 : Pearson correlation','FontSize',18);
            title('Discriminacy using Corrolation criteria','FontSize',20);
            set(gca,'fontsize',15);set(gca,'linewidth',2);
        end
        [orderedPower,orderedInd] = sort(cor,'descend');
    case 'fisher'
        S = zeros(1,nFeature);
        ui = mean(data);%Mean of each feature
        classLabels = unique(label);
        nClass = length(classLabels);
        for iFeature = 1:nFeature
            nj = zeros(1,nClass);
            uij = zeros(1,nClass);
            sigmaij = zeros(1,nClass);
            for jClass = 1:nClass
                nj(jClass) = sum(label == classLabels(jClass));
                uij(jClass) = mean(data(label == classLabels(jClass),iFeature));
                sigmaij(jClass) = var(data(label == classLabels(jClass),iFeature));
            end
            S(iFeature) = sum((uij-ui(iFeature)).^2)/sum(sigmaij);
        end
        if show
            plot(S,'k','linewidth',2);
            xlabel('Feature','FontSize',18);
            ylabel('Fisher score','FontSize',18);
            title('Discriminacy using fisher criteria','FontSize',20);
            set(gca,'fontsize',15);set(gca,'linewidth',2);
        end
        [orderedPower,orderedInd] = sort(S,'descend');
    case 'ttest'
        S = zeros(1,nFeature);
        ui = mean(data);%Mean of each feature
        classLabels = unique(label);
        nClass = length(classLabels);
        if nClass > 2
            error('more than 2 classs is not supported for t-test');
        end
        for iFeature = 1:nFeature
            nj = zeros(1,nClass);
            uij = zeros(1,nClass);
            sigmaij = zeros(1,nClass);
            for jClass = 1:nClass
                nj(jClass) = sum(label == classLabels(jClass));
                uij(jClass) = mean(data(label == classLabels(jClass),iFeature));
                sigmaij(jClass) = var(data(label == classLabels(jClass),iFeature));
            end
            S(iFeature) = abs(uij(1)-uij(2))/sqrt(sum(sigmaij./nj));
        end
        if show
            plot(S,'k','linewidth',2);
            xlabel('Feature','FontSize',18);ylabel('Fisher score','FontSize',18);
            title('Discriminacy using t-test criteria','FontSize',20);
            set(gca,'fontsize',15);set(gca,'linewidth',2);
        end
        [orderedPower,orderedInd] = sort(S,'descend');
    case 'relief'
        S = zeros(1,nFeature);
        for iSample = 1:nSample
            sample = data(iSample,:);
            sampleLabel = label(iSample);
            %FINDING NEAREST HIT
            %filter data and only take the ones in the same class
            filteredDataSameClass = data;
            filteredDataSameClass(iSample,:) = [];
            filteredLabel = label;
            filteredLabel(iSample) = [];
            filteredDataSameClass = filteredDataSameClass(filteredLabel==sampleLabel,:);
            replicateHit = repmat(sample,[size(filteredDataSameClass,1),1]);
            %finding nearest pattern
            dis = sum((replicateHit - filteredDataSameClass).^2,2);
            [disHit,ind] = min(dis);
            nearestHit = filteredDataSameClass(ind,:);
            
            %FINDING NEAREST MISS
            % filter out the data which are in the same class
            filteredDataOtherClass = data(label~=sampleLabel,:);
            replicateMiss = repmat(sample,[size(filteredDataOtherClass,1),1]);
            %finding nearest pattern
            dis  = sum((replicateMiss - filteredDataOtherClass).^2,2);
            [disMis,ind] = min(dis);
            nearestMiss = filteredDataOtherClass(ind,:);
            
            S  = S - abs(nearestHit - sample) + abs(nearestMiss - sample);
        end
        if show
            plot(S,'k','linewidth',2);
            xlabel('Feature','FontSize',18);ylabel('Relief measure','FontSize',18);
            title('Discriminacy using Relief criteria','FontSize',20);
            set(gca,'fontsize',15);set(gca,'linewidth',2);
        end
        [orderedPower,orderedInd] = sort(S,'descend');
        
    case 'infgain'
        IG = zeros(1,nFeature);
        EntropyBefore = 0;
        classLabels = unique(label);
        nClass = length(classLabels);
        for iClass = 1:nClass
            ny(iClass) = sum(label==classLabels(iClass));
            p = ny(iClass)/length(label);
            EntropyBefore = EntropyBefore - p*log2(p);
        end
        for iFeature = 1:nFeature
            for iClass = 1:nClass
                m(iClass) = mean(data(label == classLabels(iClass),iFeature));
                v(iClass) = var(data(label == classLabels(iClass),iFeature));
            end
            px = zeros(nSample,nClass);
            for iClass = 1:nClass
                px(:,iClass) = getProb(data(:,iFeature),m(iClass),v(iClass));
            end
            [temp,res] = max(px,[],2);
            EntropyAfter = 0;
            for iClass = 1:nClass
                lab = label(res == iClass);
                pBranch = length(lab)/length(label);
                for jClass = 1:nClass
                    nj(jClass) = sum(lab == classLabels(jClass));
                    p = nj(jClass)/length(lab);
                    EntropyAfter = EntropyAfter - pBranch*p*log2(p);
                end
            end
            IG(iFeature) = EntropyBefore - EntropyAfter;
        end
        [orderedPower,orderedInd] = sort(IG,'descend');
        if show
            plot(IG,'k','linewidth',2);
            xlabel('Feature','FontSize',18);ylabel('Mutual information','FontSize',18);
            title('Discriminacy using information gain criteria','FontSize',20);
            grid on;
            set(gca,'fontsize',15);set(gca,'linewidth',2);
        end
end
end

function px = getProb(point,mean,vari)
    px = 1/sqrt(2*pi*vari)*exp(-(point-mean).^2/(2*vari));
end