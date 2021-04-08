function cfg = config_preprocessing(session, user)
% Configuration file for the preprocessing pipeline
%
% Authors: Alexandre Delaux & Jean-Baptiste de Saint-Aubert, 2020

switch session
    case 1
        switch user
            case 'Alex'
                cfg.data_path = 'D:\OptoRehabEEG\Patient1001\2020-07-23\';
            case 'JB'
                cfg.data_path = '/Users/jean-baptiste/Documents/DATA/Patient1001/2020-07-23/';
        end
        cfg.filename = 'Patient1001_2020-07-23';
        cfg.chansFile = 'channels32.dat';
        cfg.n_blocks = 3;
        cfg.trials2correct = [];
        cfg.blocks_definition = [1,10;11,20;21,30]; %Indicate first and last trial for each block
        cfg.conditions_definition = {'Monoc-Glass-CR', 'Monoc-NoGlass-CR', 'Binoc-NoGlass-CR'}; % One per block row.
        cfg.bad_channels = [];
    case 2
        switch user
            case 'Alex'
                cfg.data_path = 'D:\OptoRehabEEG\Patient1001\2020-07-28\';
            case 'JB'
                cfg.data_path = '/Users/jean-baptiste/Documents/DATA/Patient1001/2020-07-28/';
        end
        cfg.filename = 'Patient1001_2020-07-28';
        cfg.chansFile = 'ChanlocsWaveguard48.ced';
        cfg.n_blocks = 10;
        cfg.trials2correct = [91];
        cfg.blocks_definition = [18,20;21,30;31,40;41,50;51,60;61,70;71,80;81,90;91,100;101,110]; %Indicate first and last trial for each block
        cfg.conditions_definition = {'Monoc-Glass-NoCR','Monoc-Glass-NoCR','Monoc-NoGlass-NoCR',...
            'Monoc-NoGlass-NoCR','Monoc-NoGlass-NoCR','Binoc-NoGlass-NoCR','Binoc-NoGlass-NoCR','Binoc-NoGlass-NoCR',...
            'Monoc-Glass-NoCR','Monoc-Glass-NoCR'}; % One per block row.
        cfg.bad_channels = [10]; %FC1 was not working;
    case 3
        switch user
            case 'Alex'
                cfg.data_path = 'D:\OptoRehabEEG\Patient1001\2020-07-29\';
            case 'JB'
                cfg.data_path = '/Users/jean-baptiste/Documents/DATA/Patient1001/2020-07-29/';
        end
        cfg.filename = 'Patient1001_2020-07-29';
        cfg.chansFile = 'ChanlocsWaveguard48.ced';
        cfg.n_blocks = 9;
        cfg.trials2correct = [];
        cfg.blocks_definition = [1,10;11,20;21,30;31,40;41,50;51,60;61,70;71,80;81,90]; %Indicate first and last trial for each block
        cfg.conditions_definition = {'Binoc-NoGlass-NoCR','Binoc-NoGlass-NoCR','Binoc-NoGlass-NoCR',...
            'Monoc-Glass-NoCR','Monoc-Glass-NoCR','Monoc-Glass-NoCR','Monoc-NoGlass-NoCR',...
            'Monoc-NoGlass-NoCR','Monoc-NoGlass-NoCR'}; % One per block row.
        cfg.bad_channels = [];
    otherwise
        error('Unknown session')
end
end