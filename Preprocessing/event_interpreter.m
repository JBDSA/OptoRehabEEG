function [EEG] = event_interpreter(EEG, blck_def, cond_def, first_tr, trials2correct)
% Interpret event codes for the EEGLAB structure file
%
% Authors: Alexandre Delaux & Jean-Baptiste de Saint-Aubert, 2020

N_events = numel(EEG.event);
%% Write the fields in the eeglab struct
fileID = fopen('events_charEx.txt', 'w');
for n=1:N_events
    fprintf(fileID,'%s\n','raw');
end
fclose(fileID);

%Create the missing fields with 'raw' data for chars
EEG = pop_editeventfield(EEG,...
    'reason','events_charEx.txt',...
    'trialIndex',zeros(1,N_events),...
    'condition','events_charEx.txt',...
    'block',zeros(1,N_events),...
    'trialType','events_charEx.txt');

EEG = eeg_checkset(EEG);
delete('events_charEx.txt');

%% Look for '0, Impedance' events
MainEvents = find(strcmp({EEG.event.type}, '0, Impedance'));
Interrupt_cnt = 0;
for e = 1:length(MainEvents)
    if e == 1
        Reason = 'ExpStart';
    elseif e == length(MainEvents)
        Reason = 'ExpEnd';
    else
        if mod(e,2)==0
            Interrupt_cnt = Interrupt_cnt+1;
            Reason = ['Interruption',num2str(Interrupt_cnt),'Start'];
        else
            Reason = ['Interruption',num2str(Interrupt_cnt),'End'];
        end
    end
    EEG = pop_editeventvals(EEG,...
        'changefield',{MainEvents(e) 'reason' Reason},...
        'changefield',{MainEvents(e) 'trialIndex' NaN},...
        'changefield',{MainEvents(e) 'condition' 'NA'},...
        'changefield',{MainEvents(e) 'block' NaN},...
        'changefield',{MainEvents(e) 'trialType' 'NA'});
end
fprintf('%d interruption(s) found.\n',Interrupt_cnt);

%% Look for '1' events: trial start
TrialStarts = find(strcmp({EEG.event.type}, '1'));
N_trials = length(TrialStarts);
for tr = 1:N_trials
    b = find(tr+first_tr-1>=blck_def(:,1) & tr+first_tr-1<=blck_def(:,2));
    cond = cond_def{b};
    
    i = TrialStarts(tr);
    if tr == N_trials
        i_max = MainEvents(end);
    else
        i_max = TrialStarts(tr+1);
    end
    
    % Loop to investigate events within trials: search for the trial type
    while i < i_max && (strcmp(EEG.event(i+1).type,'2') || strcmp(EEG.event(i+1).type,'3'))
        i = i+1;
    end
    if i == TrialStarts(tr) || sum(trials2correct == tr+first_tr-1)>0
        fprintf('Trial %d: missing trial type.\n', tr+first_tr-1)
        trialtype = input('Please enter the trial type (''Object'' or ''NoObject''): ');
    else
        switch EEG.event(i).type
            case '2'
                trialtype = 'NoObject';
            case '3'
                trialtype = 'Object';
            otherwise
                error('Bug in the code(trial type detection), please correct')
        end
    end
    
    % Continue the loop
    i = i+1;
    while i < i_max
        switch EEG.event(i).type
            case '4'
                Reason = 'OpenEyes';
            case '5'
                Reason = 'CloseEyes';
            case '8'
                Reason = 'ObjectPresent';
            case '16'
                Reason = 'ObjectAbsent';
            case '0, Impedance'
                break
            otherwise
                error('Unknown event code, please update the interpreter.')
        end
        EEG = pop_editeventvals(EEG,...
            'changefield',{i 'reason' Reason},...
            'changefield',{i 'trialIndex' tr+first_tr-1},...
            'changefield',{i 'condition' cond},...
            'changefield',{i 'block' b},...
            'changefield',{i 'trialType' trialtype});
        i = i+1;
    end
    
    % Fill info for trial start:
    EEG = pop_editeventvals(EEG,...
        'changefield',{TrialStarts(tr) 'reason' 'Start'},...
        'changefield',{TrialStarts(tr) 'trialIndex' tr+first_tr-1},...
        'changefield',{TrialStarts(tr) 'condition' cond},...
        'changefield',{TrialStarts(tr) 'block' b},...
        'changefield',{TrialStarts(tr) 'trialType' trialtype});
end
fprintf('%d trials found.\n',N_trials);

%% Delete the trial type events that are useless for analysis
Trials2delete = find(strcmp({EEG.event.type}, '2') | strcmp({EEG.event.type}, '3'));
EEG = pop_editeventvals(EEG,'delete',Trials2delete);
fprintf('%d events deleted.\n',length(Trials2delete));

EEG = eeg_checkset(EEG);
end