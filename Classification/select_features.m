function [Features, chan_labels, freq_labels] = select_features(Power_all,chan_sel,chanlocs,freq_sel)
% Perform selection of features from the full matrix of features and
% convert it to a 2 dimensional matrix (feature x trial)
%
% Author: Alexandre Delaux, 2020

nb_trials = size(Power_all,3);
if ischar(chan_sel) && ischar(freq_sel)
    % Then it's 'all' for sure for both dimensions
    nb_chans = size(Power_all,1);
    chan_labels = {chanlocs.labels};
    nb_freqs = size(Power_all,2);
    freq_labels = 1:nb_freqs;
    Features = reshape(Power_all, [nb_chans*nb_freqs,nb_trials]);
elseif ischar(chan_sel)
    nb_chans = size(Power_all,1);
    chan_labels = {chanlocs.labels};
    freq_labels = [];
    Power_sel = [];
    for i = 1:size(freq_sel,1)
        Power_sel = cat(2, Power_sel, Power_all(:,freq_sel(i,1):freq_sel(i,2),:));
        freq_labels = cat(1,freq_labels, freq_sel(i,1):freq_sel(i,2));
    end
    nb_freqs = numel(freq_labels);
    Features = reshape(Power_sel, [nb_chans*nb_freqs,nb_trials]);
else
    nb_chans = numel(chan_sel);
    chan_labels = chan_sel;
    Power_sel = [];
    for ch = 1:nb_chans
        ind = strcmp({chanlocs.labels},chan_sel{ch});
        Power_sel = cat(1, Power_sel, Power_all(ind,:,:));
    end
    
    if ~ischar(freq_sel)
        freq_labels = [];
        Power_sel2 = [];
        for i = 1:size(freq_sel,1)
            Power_sel2 = cat(2, Power_sel2, Power_sel(:,freq_sel(i,1):freq_sel(i,2),:));
            freq_labels = cat(1,freq_labels, freq_sel(i,1):freq_sel(i,2));
        end
        nb_freqs = numel(freq_labels);
        Features = reshape(Power_sel2, [nb_chans*nb_freqs,nb_trials]);
    else
        nb_freqs = size(Power_all,2);
        freq_labels = 1:nb_freqs;
        Features = reshape(Power_sel, [nb_chans*nb_freqs,nb_trials]);
    end
end
end