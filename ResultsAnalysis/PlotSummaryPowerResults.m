% Author: Alexandre Delaux, 2020

clear
close all

user = 'Alex';
freqs = 1:40;
normStyle = 'perFeat';

if ~exist('EEG', 'var')
    switch user
        case 'Alex'
            launchEEGLAB
        case 'JB'
            eeglab
    end
end

pipeline_ind = 5;
config = config_classifier(user,pipeline_ind,normStyle,1);
Power_all_EC = [];
Labels_all_EC = [];
Power_all_EO = [];
Labels_all_EO = [];
n_conds = 4;
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
    
    %Trials with stimulation
    StimTrials = find(contains(condition,'-Glass-'));
    nb_trials_stim = length(StimTrials);
    % Compute PSD and labels for each trial
    PSD_EC = zeros(EEG_EC.nbchan, length(freqs), nb_trials_stim);
    labels = trialType(StimTrials)+n_conds-1;
    for t = 1:nb_trials_stim
        PSD_EC(:,:,t) = pwelch(squeeze(EEG_EC.data(:,:,StimTrials(t)))', EEG_EC.srate,  EEG_EC.srate/2, freqs, EEG_EC.srate)';
    end
    
    % Convert to dB
    PSD_EC_dB = 10*log10(PSD_EC);
    Power_all_EC = cat(3,Power_all_EC,PSD_EC_dB);
    Labels_all_EC = [Labels_all_EC; labels];
    
    %Trials without stimulation
    NoStimTrials = find(contains(condition,'-NoGlass-'));
    nb_trials_nostim = length(NoStimTrials);
    % Compute PSD and labels for each trial
    PSD_EC = zeros(EEG_EC.nbchan, length(freqs), nb_trials_nostim);
    labels = trialType(NoStimTrials)+1;
    for t = 1:nb_trials_nostim
        PSD_EC(:,:,t) = pwelch(squeeze(EEG_EC.data(:,:,NoStimTrials(t)))', EEG_EC.srate,  EEG_EC.srate/2, freqs, EEG_EC.srate)';
    end
    
    % Convert to dB
    PSD_EC_dB = 10*log10(PSD_EC);
    Power_all_EC = cat(3,Power_all_EC,PSD_EC_dB);
    Labels_all_EC = [Labels_all_EC; labels];
    
    %% Eyes-open period is the real signal of interest
    EEG_EO = pop_epoch(EEG, {'4'}, [0 15+1/EEG.srate], 'epochinfo', 'yes');
    % Select trials of the condition with glasses.
    condition = cell(EEG_EO.trials,1);
    trialType = zeros(EEG_EO.trials,1);
    block = zeros(EEG_EO.trials,1);
    for t = 1:EEG_EO.trials
        condition(t) = unique(EEG_EO.epoch(t).eventcondition);
        block(t) = EEG_EO.epoch(t).eventblock{1};
        if strcmp(unique(EEG_EO.epoch(t).eventtrialType),'Object')
            trialType(t) = 1;
        end
    end
    
    % Trials with stimulation
    StimTrials = find(contains(condition,'-Glass-'));
    nb_trials_stim = length(StimTrials);
    % Compute PSD and labels for each trial
    PSD_EO = zeros(EEG_EO.nbchan, length(freqs), nb_trials_stim);
    labels = trialType(StimTrials)+n_conds-1; % Trial type: Object vs NoObject
    
    for t = 1:nb_trials_stim
        PSD_EO(:,:,t) = pwelch(squeeze(EEG_EO.data(:,:,StimTrials(t)))', EEG_EO.srate,  EEG_EO.srate/2, freqs, EEG_EO.srate)';
    end
    
    % Convert to dB
    PSD_EO_dB = 10*log10(PSD_EO);
    Power_all_EO = cat(3,Power_all_EO,PSD_EO_dB);
    Labels_all_EO = [Labels_all_EO; labels];
    
    %Trials without stimulation
    NoStimTrials = find(contains(condition,'-NoGlass-'));
    nb_trials_nostim = length(NoStimTrials);
    % Compute PSD and labels for each trial
    PSD_EO = zeros(EEG_EO.nbchan, length(freqs), nb_trials_nostim);
    labels = trialType(NoStimTrials)+1;
    for t = 1:nb_trials_nostim
        PSD_EO(:,:,t) = pwelch(squeeze(EEG_EO.data(:,:,NoStimTrials(t)))', EEG_EO.srate,  EEG_EO.srate/2, freqs, EEG_EO.srate)';
    end
    
    % Convert to dB
    PSD_EO_dB = 10*log10(PSD_EO);
    Power_all_EO = cat(3,Power_all_EO,PSD_EO_dB);
    Labels_all_EO = [Labels_all_EO; labels];
end

trials_count = zeros(1,n_conds);
for c = 1:n_conds
    trials_count(c) = sum(Labels_all_EO==c);
    switch c
        case 1
            ConditionNames{c} = 'NoStim-NoObj';
        case 2
            ConditionNames{c} = 'NoStim-Obj';
        case 3
            ConditionNames{c} = 'Stim-NoObj';
        case 4
            ConditionNames{c} = 'Stim-Obj';
    end
end

selection = struct('chan', {'O1','Oz'}, 'freq', [14]);
% Average of all features:
all_ch = [];
all_f = [];
for sel = 1:size(selection,2)
    all_ch = [all_ch,find(strcmp({EEG.chanlocs.labels}, selection(sel).chan))];
    all_f = [all_f,selection(sel).freq];
end

all_ch = unique(all_ch);
all_f = unique(all_f);

% Fill vectors with nans to get an homogeneous array
data4boxplot = nan(max(trials_count),n_conds*2);
labelsBoxplot = cell(1,n_conds*2);
for c = 1:n_conds
    data4boxplot(1:trials_count(c),floor(c/3)*2+c) = squeeze(mean(Power_all_EC(all_ch,all_f,Labels_all_EC==c),[1,2]));
    data4boxplot(1:trials_count(c),floor(c/3)*2+c+2) = squeeze(mean(Power_all_EO(all_ch,all_f,Labels_all_EO==c),[1,2]));
    labelsBoxplot{floor(c/3)*2+c} = sprintf('%s-EC (%d trials)', ConditionNames{c},trials_count(c));
    labelsBoxplot{floor(c/3)*2+c+2} = sprintf('%s-EO (%d trials)', ConditionNames{c},trials_count(c));
end

%% Only the main comparison
figure
hold on
boxplot(data4boxplot(:,end-1:end),'Labels',labelsBoxplot(end-1:end));
plot(1.2+rand(trials_count(3),1)*0.05, data4boxplot(1:trials_count(3),end-1),...
    'k','LineStyle', 'none', 'marker','.', 'markersize',15)
plot(2.2+rand(trials_count(4),1)*0.05, data4boxplot(1:trials_count(4),end),...
    'k','LineStyle', 'none', 'marker','.', 'markersize',15)
xtickangle(45)
ylabel('Power amplitude (dB)')
ylim([-3;5])
title(['Average power in ',cell2str({selection.chan}, ','),' channel(s) at 14Hz']);

%% Topoplots
Clims = [min(Power_all_EO(:,all_f,Labels_all_EO>2), [], 'all'), max(Power_all_EO(:,all_f,Labels_all_EO>2), [], 'all')]/2;
chanlocs_custom = EEG.chanlocs;
for ch = setdiff(1:48,[30,31,48])
    chanlocs_custom(ch).labels = '.';
end

figure
subplot(1,2,1)
p1 = topoplot(mean(Power_all_EO(:,all_f,Labels_all_EO==3),3), EEG.chanlocs,...
    'maplimits', Clims, 'electrodes', 'on', 'conv', 'off');
title('Stimulation - No Object')
subplot(1,2,2)
topoplot(mean(Power_all_EO(:,all_f,Labels_all_EO==4),3), EEG.chanlocs,...
    'maplimits', Clims, 'electrodes', 'on', 'conv', 'off');
title('Stimulation - Object')
cb =colorbar('AxisLocation', 'out', 'Position', [0.91,0.15,0.02,0.7]);
cb.Label.String = 'Mean power amplitude (dB)';
set(cb, 'FontSize', 12)
suptitle('Mean (across trials) of power amplitude at 14 Hz averaged over the Eyes Open period')
