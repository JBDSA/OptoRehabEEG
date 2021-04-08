% Authors: Alexandre Delaux & Jean-Baptiste de Saint-Aubert, 2020

%PREPROCESSING AND CLEANING OF DATA SEPARATEDLY ACCORDING TO THE
%RECORDING PROTOCOL. ALLOWS TO SAVE THE EEG STRUCTURE FOR EACH SESSION

clear
close all

% SET THE USER & THE SESSION
user = 'Alex';
session = 2;

if ~exist('EEG', 'var')
    switch user
        case 'Alex'
            launchEEGLAB
        case 'JB'
            eeglab
    end
end

config = config_preprocessing(session,user); % 1 = session 1, 2 = session 2...

% set the following parameters carefully:
newdataset = false;
select_data = true;
skip_asr = true;
automatic_ICs = true;
pipeline_folder = 'Preprocessing5_noASR_SelectTrial_autoICs';

% general preprocessing parameters:
lowcutoff = 1;
highcutoff = 40;
resample_freq = 250;
bufferBefore = 1; % in seconds, duration to keep before each trial if select_data == true
bufferAfter = 4; % in seconds, duration to keep after each trial if select_data == true

if newdataset
    % loading the eeg data file as a .cnt extension as exported from amplifier
    EEG = pop_loadeep_v4_custom([config.data_path, config.filename, '.cnt']);
    
    %Loading channels locations: it has to be done once via ASA software and it is going to be the same for every subject
    EEG.chanlocs = readlocs([config.data_path, config.chansFile]);
    if ~isempty(config.bad_channels)
        EEG = pop_select(EEG,'nochannel',config.bad_channels);
    end
    %If you want to visualize the electrodes:
    %figure; topoplot(EEG.data(:,1)',EEG.chanlocs, 'style', 'blank', 'electrodes', 'labels');
    
    % Rename Events
    EEG = eeg_checkset(EEG, 'makeur');
    EEG = event_interpreter(EEG,config.blocks_definition,config.conditions_definition,...
        min(config.blocks_definition(:)),config.trials2correct);
    
    % Save the raw dataset
    EEG = pop_saveset(EEG, 'filename',[config.filename '_raw.set'],'filepath',config.data_path);
else
    EEG = pop_loadset('filename',[config.filename '_raw.set'],'filepath',config.data_path);
end

% Resampling
EEG = pop_resample(EEG, resample_freq);
EEG = eeg_checkset(EEG);

% Filtering between freq limits
EEG_filt = custom_filter(EEG, lowcutoff, highcutoff, user);

if select_data
    %% Select data relative to trials only
    first_tr = min(config.blocks_definition(:));
    last_tr = max(config.blocks_definition(:));
    n_trials = last_tr - first_tr + 1;
    selected_intervals = zeros(n_trials,2);
    for tr = 1:n_trials
        e_start = find([EEG.event.trialIndex] == tr+first_tr-1, 1);
        selected_intervals(tr,1) = (EEG.times(round(EEG.event(e_start).latency))/1000)-bufferBefore;
        e_end = find([EEG.event.trialIndex] == tr+first_tr-1, 1, 'last');
        selected_intervals(tr,2) = (EEG.times(round(EEG.event(e_end).latency))/1000)+bufferAfter;
    end
    % Sanity checks:
    if sum(diff(selected_intervals,1,1)>0, 'all') < (n_trials-1)*2; error('Intervals for rejection ill-defined');end
    if sum(diff(selected_intervals,1,2)>0) < n_trials; error('Intervals for rejection ill-defined');end
    tr=1;
    while tr < size(selected_intervals,1)
        if selected_intervals(tr,2)-selected_intervals(tr+1,1)>0
            % Merge intervals since the time between blocks in shorter than the margins used
            selected_intervals(tr,2) = selected_intervals(tr+1,2);
            selected_intervals(tr+1,:) = [];
        else
            tr=tr+1;
        end
    end
    EEG_select = pop_select(EEG_filt,'time',selected_intervals);
    EEG_select = eeg_checkset(EEG_select);
    % Check whether we still have enough data for ICA (rule of thumb)
    if EEG_select.pnts < (EEG_select.nbchan^2)*30
        warning('Not enough points to do ICA on the reduced dataset.\n Using the full dataset instead.')
        EEG_select = EEG_filt;
        skip_asr = false;
    end
else
    EEG_select = EEG_filt;
end

% All-in-one function for artifact removal, including ASR.
% [EEG,HP,BUR] = clean_artifacts(EEG, Options...)
% This function removes flatline channels, low-frequency drifts, noisy channels, short-time bursts
% and incompletely repaird segments from the data.
% Tip: Any of the core parameters can also be passed in as [] to use the respective default of the underlying functions, or as 'off' to disable
% it entirely.
if skip_asr
    % Use the function for channel rejection and very bad temporal segments only
    [EEG_asr,~,~] = clean_artifacts(EEG_select, 'Highpass', 'off', 'BurstCriterion', 20, 'BurstRejection', 'off');
    if isfield(EEG_asr.etc,'clean_channel_mask')
        EEG_preproc = pop_select(EEG_select,'nochannel',find(EEG_asr.etc.clean_channel_mask==0));
        EEG_preproc.etc.clean_channel_mask = EEG_asr.etc.clean_channel_mask;
        N_removed_chans = sum(~EEG_asr.etc.clean_channel_mask);
        
        %Interpolate all the removed channels
        EEG_preproc = pop_interp(EEG_preproc, EEG.chanlocs, 'spherical');
    else
        EEG_preproc = EEG_select;
        EEG_preproc.etc.clean_channel_mask = true(EEG_preproc.nbchan,1);
        N_removed_chans = 0;
    end
    if isfield(EEG_asr.etc,'clean_sample_mask') && sum(EEG_asr.etc.clean_sample_mask)<EEG_asr.pnts
        sample_mask = EEG_asr.etc.clean_sample_mask;
        if sample_mask(1)
            interval_starts = [1, find(diff(sample_mask)==1)+1];
        else
            interval_starts = find(diff(sample_mask)==1)+1;
        end
        if sample_mask(end)
            interval_ends = [find(diff(sample_mask)==-1),length(sample_mask)];
        else
            interval_ends = find(diff(sample_mask)==-1);
        end
        EEG_preproc = pop_select(EEG_preproc,'time',cat(2,interval_starts',interval_ends'));
        EEG_preproc = eeg_checkset(EEG_preproc);
        EEG_preproc.etc.clean_sample_mask = sample_mask;
    else
        EEG_preproc.etc.clean_sample_mask = true(EEG_preproc.pnts,1);
    end
    
    %Visualize the difference, if I'm not mistaken, it should be between the new and the old data set
    vis_artifacts(EEG_asr,EEG_select);
    %vis_artifacts(EEG_preproc,EEG_select); % Doesn't work if asr removes a channel
    clear EEG_asr
else
    [EEG_preproc,~,~] = clean_artifacts(EEG_select, 'Highpass', 'off', 'BurstCriterion', 20, 'BurstRejection', 'off');
    if isfield(EEG_preproc.etc,'clean_channel_mask')
        N_removed_chans = sum(~EEG_preproc.etc.clean_channel_mask);
        %Interpolate all the removed channels
        EEG_preproc = pop_interp(EEG_preproc, EEG.chanlocs, 'spherical');
    else
        EEG_preproc.etc.clean_channel_mask = true(EEG_preproc.nbchan,1);
        N_removed_chans = 0;
    end
end

% Re-reference the data to average
EEG_preproc.nbchan = EEG_preproc.nbchan+1;
EEG_preproc.data(end+1,:) = zeros(1, EEG_preproc.pnts);
EEG_preproc.chanlocs(EEG_preproc.nbchan).labels = 'initialReference';
EEG_preproc = pop_reref(EEG_preproc, []);
EEG_preproc = pop_select(EEG_preproc,'nochannel',{'initialReference'});

% Force interpolation to 48 channels (already done for bad channels found in pre-proc, here for bad channels hardcoded in config_preprocessing)
EEG_preproc = pop_interp(EEG_preproc, readlocs([config.data_path, config.chansFile]), 'spherical');

%Run ICA
EEG_ica = pop_runica(EEG_preproc, 'pca', EEG_preproc.nbchan - N_removed_chans - length(config.bad_channels),... % adapting rank
    'extended',1, 'maxsteps', 512);
EEG_ica = iclabel(EEG_ica, 'default');
thresholds_default = [0.35,0.30,0.04,0.03,0.84,0.05,0.26];
EEG_ica = IC_categorization(EEG_ica, thresholds_default);

%Save the ica dataset
EEG_ica = pop_saveset(EEG_ica, 'filename',[config.filename '_afterICA.set'],'filepath',...
    [config.data_path, pipeline_folder, filesep]);

if automatic_ICs
    %% automatic IC selection
    [ALLEEG, EEG_final, CURRENTSET, ICs2keep, ICs2throw, ICsbrain] =...
        select_plot_ICs(EEG_ica, ALLEEG, CURRENTSET, [1], 'mostProbable',...
        [config.data_path, pipeline_folder,filesep], config.filename);
else
    %% Manual ICs selection
    pop_viewprops(EEG_ica, 0, 1:size(EEG_ica.icaact,1), {'freqrange', [lowcutoff highcutoff]}, {}, 1, 'ICLabel'); % for component properties
    
    %Removing components--components to be removed are plotted
    kept_comp = input('Components to keep: '); % enter [1,3,4,8,10...]
    rem_comp = setdiff(1:size(EEG_ica.icaact,1),kept_comp); % get the components to remove...
    EEG_final = pop_subcomp(EEG_ica, rem_comp, 0); % ...and remove them from EEG_final.
    EEG_final.etc.ic_cleaning = struct('method', 'manual inspection',...
        'keptClasses', 1,'keptICs', kept_comp, 'thrownICs', rem_comp);
end

%Save the final dataset
EEG_final = pop_saveset(EEG_final, 'filename',[config.filename '_final.set'],'filepath',...
    [config.data_path, pipeline_folder, filesep]);

