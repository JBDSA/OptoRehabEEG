% custom_filter() - Filtering of EEG data
% Adapted from bemobil_filter() from the bemobil pipeline (Marius Klug)
%
% Usage:
%   >>  [ ALLEEG EEG CURRENTSET ] = bemobil_filter(ALLEEG, EEG, CURRENTSET, locutoff, highcutoff);
%   >>  [ ALLEEG EEG CURRENTSET ] = bemobil_filter(ALLEEG, EEG, CURRENTSET, locutoff, highcutoff, out_filename, out_filepath);
%
% Inputs:
%   EEG                     - current EEGLAB EEG structure
%   lowcutoff               - low cut off frequency for firfilt filering, if [], no filter will be applied
%   highcutoff              - high cut of frequency, if [], no filter will be applied
%
% Outputs:
%   EEG                     - current EEGLAB EEG structure
%
%   .set data file of current EEGLAB EEG structure stored on disk (OPTIONALLY)
%
% Author: Alexandre Delaux, 2020
% Based on the bemobil_filter function from the bemobil pipeline (Klug & Gehrke, 2018)

function [EEG] = custom_filter(EEG, lowcutoff, highcutoff, user)

if ~isempty(lowcutoff) || ~isempty(highcutoff)
    EEG.etc.filter.type = 'Hamming windowed sinc FIR filter (zero-phase)';
else
    error('No filter cutoffs specified, what was your plan here?!')
end

% Constants
TRANSWIDTHRATIO = 0.25;
fNyquist = EEG.srate/2;

%% High pass
if ~isempty(lowcutoff)
    switch user
        case 'Alex'
            [EEG, ~, ~, order] = pop_eegfiltnew(EEG, lowcutoff, 0, [], 0, [], 1);
        case 'JB'
            [EEG, ~, ~, order] = pop_eegfiltnew_JB(EEG, lowcutoff, 0, [], 0, [], 1);
    end
    EEG = eeg_checkset(EEG);
    
    passband_edge = lowcutoff;
    maxDf = passband_edge; % Band-/highpass
    % Default code from pop_eegfiltnew
    transition_bandwidth = min([max([maxDf * TRANSWIDTHRATIO 2]) maxDf]);
    cutoff_freq = passband_edge - transition_bandwidth/2;
    disp(['Highpass filtered the data with ' num2str(cutoff_freq) 'Hz cutoff, '...
        num2str(transition_bandwidth) 'Hz transition bandwidth, '...
        num2str(passband_edge) 'Hz passband edge, and '...
        num2str(order) ' order.']);
    
    % removing and remaking the filed is necessary for the order of the struct fields to be identical
    EEG.etc.filter.highpass.cutoff = cutoff_freq;
    EEG.etc.filter.highpass.transition_bandwidth = transition_bandwidth;
    EEG.etc.filter.highpass.passband = passband_edge;
    EEG.etc.filter.highpass.order = order;
    close(gcf)
else
    if ~isfield(EEG.etc.filter,'highpass')
        EEG.etc.filter.highpass = 'not applied';
    end
end

%% Low pass
if ~isempty(highcutoff)
    if highcutoff > fNyquist - 1
        disp('Warning: Cannot filter higher than Nyquist frequency.');
        highcutoff = fNyquist - 1;
        disp(['Now continuing with highest possible frequency: ' num2str(highcutoff)]);
    end
    
    switch user
        case 'Alex'
            [EEG, ~, ~, order] = pop_eegfiltnew(EEG, 0, highcutoff, [], 0, [], 1);
        case 'JB'
            [EEG, ~, ~, order] = pop_eegfiltnew_JB(EEG, 0, highcutoff, [], 0, [], 1);
    end
    EEG = eeg_checkset(EEG);
    
    passband_edge = highcutoff;
    maxDf = fNyquist - passband_edge; % Band-/highpass
    % Default code from pop_eegfiltnew
    transition_bandwidth = min([max([passband_edge * TRANSWIDTHRATIO 2]) maxDf]);
    cutoff_freq = passband_edge - transition_bandwidth/2;
    
    disp(['Lowpass filtered the data with ' num2str(cutoff_freq) 'Hz cutoff, '...
        num2str(transition_bandwidth) 'Hz transition bandwidth, '...
        num2str(passband_edge) 'Hz passband edge, and '...
        num2str(order) ' order.']);
    
    % removing and remaking the filter struct field is necessary for the order of the struct fields to be identical
    EEG.etc.filter.lowpass.cutoff = cutoff_freq;
    EEG.etc.filter.lowpass.transition_bandwidth = transition_bandwidth;
    EEG.etc.filter.lowpass.passband = passband_edge;
    EEG.etc.filter.lowpass.order = order;
    close(gcf)
else
    if ~isfield(EEG.etc.filter,'lowpass')
        EEG.etc.filter.lowpass = 'not applied';
    end
end
end
