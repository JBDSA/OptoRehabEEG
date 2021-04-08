% Author: Alexandre Delaux, 2020

if ~exist('EEG', 'var')
    switch user
        case 'Alex'
            launchEEGLAB
        case 'JB'
            eeglab
    end
end

config = config_classifier(user,pipeline_ind,normStyle,2);
n_conds = numel(config.conditions);
Power_all_EC = [];
Labels_all_EC = [];
Power_all_EO = [];
Labels_all_EO = [];
for d = 1:numel(config.days)
    disp(['Loading session ' config.days{d}])
    EEG = pop_loadset('filename',['Patient1001_', config.days{d}, '_final.set'],...
        'filepath',[config.workingFolder, config.days{d}, filesep, config.pipeline, filesep]);
    
    %% Eyes-closed period serves as a control
    EEG_EC = pop_epoch(EEG, {'4'}, [-5 1/EEG.srate], 'epochinfo', 'yes');
    % Select trials of the condition with glasses.
    condition = cell(EEG_EC.trials,1);
    trialType = zeros(EEG_EC.trials,1);
    for t = 1:EEG_EC.trials
        condition(t) = unique(EEG_EC.epoch(t).eventcondition);
        if strcmp(unique(EEG_EC.epoch(t).eventtrialType),'Object')
            trialType(t) = 1;
        end
    end
    trials2keep = find(contains(condition,'Monoc-NoGlass-'));
    nb_trials = length(trials2keep);
    
    % Compute PSD and labels for each trial
    PSD_EC = zeros(EEG_EC.nbchan, length(freqs), nb_trials);
    labels = trialType(trials2keep); % Trial type: Object vs NoObject
    for t = 1:nb_trials
        PSD_EC(:,:,t) = pwelch(squeeze(EEG_EC.data(:,:,trials2keep(t)))', EEG_EC.srate,  EEG_EC.srate/2, freqs, EEG_EC.srate)';
    end
    
    % Convert to dB
    PSD_EC_dB = 10*log10(PSD_EC);
    % Normalize across channels and trials with respect to each frequency
    switch normStyle
        case 'acrossChans'
            mu = mean(PSD_EC_dB, [1,3]);
            sigma = std(PSD_EC_dB,[],[1,3]);
            PSD_EC_dB_norm = (PSD_EC_dB - repmat(mu,EEG_EC.nbchan,1,nb_trials))./repmat(sigma,EEG_EC.nbchan,1,nb_trials);
        case 'perFeat'
            mu = mean(PSD_EC_dB, 3);
            sigma = std(PSD_EC_dB,[],3);
            PSD_EC_dB_norm = (PSD_EC_dB - repmat(mu,1,1,nb_trials))./repmat(sigma,1,1,nb_trials);
    end
    Power_all_EC = cat(3,Power_all_EC,PSD_EC_dB_norm);
    Labels_all_EC = [Labels_all_EC; labels];
    
    %% Eyes-open period is the real signal of interest
    EEG_EO = pop_epoch(EEG, {'4'}, [0 15+1/EEG.srate], 'epochinfo', 'yes');
    % Select trials of the condition with glasses.
    condition = cell(EEG_EO.trials,1);
    trialType = zeros(EEG_EO.trials,1);
    for t = 1:EEG_EO.trials
        condition(t) = unique(EEG_EO.epoch(t).eventcondition);
        if strcmp(unique(EEG_EO.epoch(t).eventtrialType),'Object')
            trialType(t) = 1;
        end
    end
    trials2keep = find(contains(condition,'Monoc-NoGlass-'));
    nb_trials = length(trials2keep);
    
    % Compute PSD and labels for each trial
    PSD_EO = zeros(EEG_EO.nbchan, length(freqs), nb_trials);
    labels = trialType(trials2keep); % Trial type: Object vs NoObject
    for t = 1:nb_trials
        PSD_EO(:,:,t) = pwelch(squeeze(EEG_EO.data(:,:,trials2keep(t)))', EEG_EO.srate,  EEG_EO.srate/2, freqs, EEG_EO.srate)';
    end
    
    % Convert to dB
    PSD_EO_dB = 10*log10(PSD_EO);
    % Normalize across channels and trials with respect to each frequency
    switch normStyle
        case 'acrossChans'
            mu = mean(PSD_EO_dB, [1,3]);
            sigma = std(PSD_EO_dB,[],[1,3]);
            PSD_EO_dB_norm = (PSD_EO_dB - repmat(mu,EEG_EO.nbchan,1,nb_trials))./repmat(sigma,EEG_EO.nbchan,1,nb_trials);
        case 'perFeat'
            mu = mean(PSD_EO_dB, 3);
            sigma = std(PSD_EO_dB,[],3);
            PSD_EO_dB_norm = (PSD_EO_dB - repmat(mu,1,1,nb_trials))./repmat(sigma,1,1,nb_trials);
    end
    Power_all_EO = cat(3,Power_all_EO,PSD_EO_dB_norm);
    Labels_all_EO = [Labels_all_EO; labels];
end