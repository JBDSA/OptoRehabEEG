function [ ] = plotCVstats(CVstats, features2test, saving_params)
%Figures for visualization of classifier performance
%
% Author: Alexandre Delaux, 2020

n_folds = size(CVstats.training.Err,2);

if saving_params.error
    figure
    errorbar(features2test, 100*mean(CVstats.training.Err,2), 100*std(CVstats.training.Err,[],2)./sqrt(n_folds), 'Linewidth',2)
    hold on
    switch saving_params.CV
        case 'folds'
            errorbar(features2test, 100*mean(CVstats.testing.Err,2), 100*std(CVstats.testing.Err,[],2)./sqrt(n_folds), 'Linewidth',2)
        case 'LOO'
            plot(features2test, 100*mean(CVstats.testing.Err,2), '-o', 'Linewidth',2);
    end
    yline(100*CVstats.random.Err, 'k--');
    ylim([0,100])
    xlabel('Number of features used')
    ylabel('Percentage of error')
    legend({'Training Error','Testing Error','Chance level'},'Location', 'best')
    switch saving_params.CV
        case 'folds'
            title(['Classification errors (mean across ', num2str(n_folds),' folds)'])
            saveCurrentFig(saving_params.folder, sprintf('%s_ClassErr_%dfolds%s',saving_params.model,n_folds,saving_params.suffix), {'png'}, [])
        case 'LOO'
            title('Classification errors (Leave-one-out)')
            saveCurrentFig(saving_params.folder, sprintf('%s_ClassErr_LOO%s',saving_params.model,saving_params.suffix), {'png'}, [])
    end
end

if saving_params.errorBal && ~strcmp(saving_params.CV,'LOO')
    figure
    errorbar(features2test, 100*mean(CVstats.training.Err_bal,2), 100*std(CVstats.training.Err_bal,[],2)./sqrt(n_folds), 'Linewidth',2)
    hold on
    errorbar(features2test, 100*mean(CVstats.testing.Err_bal,2), 100*std(CVstats.testing.Err_bal,[],2)./sqrt(n_folds), 'Linewidth',2)
    yline(100*CVstats.random.Err_bal, 'k--');
    ylim([0,100])
    xlabel('Number of features used')
    ylabel('Percentage of error')
    legend({'Balanced Training Error','Balanced Testing Error','Chance level'},'Location', 'best')
    title(['Classification errors (mean across ', num2str(n_folds),' folds)'])
    saveCurrentFig(saving_params.folder, sprintf('%s_ClassErrBal_%dfolds%s',saving_params.model,n_folds,saving_params.suffix), {'png'}, [])
end

if saving_params.AUC && ~strcmp(saving_params.CV,'LOO')
    figure
    errorbar(features2test, 100*mean(CVstats.training.AUC,2),100*std(CVstats.training.AUC,[],2)./sqrt(n_folds), 'Linewidth',2)
    hold on
    errorbar(features2test, 100*mean(CVstats.testing.AUC,2), 100*std(CVstats.testing.AUC,[],2)./sqrt(n_folds), 'Linewidth',2)
    yline(CVstats.random.AUC*100, 'k--');
    xlabel('Number of features used')
    ylabel('AUC (%)')
    ylim([0,100])
    legend({'Training','Testing'},'Location', 'best')
    title('AUC (mean across folds)')
    saveCurrentFig(saving_params.folder, sprintf('%s_AUC_%dfolds%s',saving_params.model,n_folds,saving_params.suffix), {'png'}, [])
end

if saving_params.CM
    n_feats = length(features2test);
    figure
    for f=1:n_feats
        subplot(2,n_feats/2,f)
        plotConfMat(squeeze(mean(squeeze(CVstats.training.CM(f,:,:,:)),1))', saving_params.classes)
        title([num2str(features2test(f)),' features used'])
    end
    switch saving_params.CV
        case 'folds'
            suptitle(['Training results (mean across ', num2str(n_folds),' folds)'])
        case 'LOO'
            suptitle('Training results (Leave-one-out)')
    end
    
    if n_feats<=4
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TrainCM', saving_params.suffix], {'png'},[])
    elseif n_feats<=6
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TrainCM', saving_params.suffix], {'png'}, [1000,800])
    else
        %To define when the case occurs
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TrainCM', saving_params.suffix], {'png'},[])
    end
    
    figure
    for f=1:n_feats
        subplot(2,n_feats/2,f)
        if strcmp(saving_params.CV,'LOO')
            plotConfMat(squeeze(mean(squeeze(CVstats.testing.CM(f,:,:,:)),1))', saving_params.classes, true)
        else
            plotConfMat(squeeze(mean(squeeze(CVstats.testing.CM(f,:,:,:)),1))', saving_params.classes)
        end
        title([num2str(features2test(f)),' features used'])
    end
    switch saving_params.CV
        case 'folds'
            suptitle(['Test results (mean across ', num2str(n_folds),' folds)'])
        case 'LOO'
            suptitle('Test results (Leave-one-out)')
    end
    
    if n_feats<=4
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TestCM', saving_params.suffix], {'png'}, [])
    elseif n_feats<=6
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TestCM', saving_params.suffix], {'png'}, [1000,800])
    else
        %To define when the case occurs
        saveCurrentFig(saving_params.folder, [saving_params.model,'_TestCM', saving_params.suffix], {'png'}, [])
    end
end
end

