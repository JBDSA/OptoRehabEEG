function visualize_Fischer(OrderInd,scoreOfFeatures,max_feat,chan_labels,freq_labels)
% Plot the Fischer score in 2D image to visualize which features are the most discriminant
% Inputs:
% OrderInd          - Vector of features' ranking as outputted by rankfeat()
% scoreOfFeatures   - Vector of features' score (corresponding to
%                       OrderInd). orderedPower ouput from rankfeat().
% max_feat          - Maximum number of features to plot (if not 'all', the
%                       features excluded will automatically appear with a 0 score on the plot.
% chan_labels       - labels of channels ({EEG.chanlocs.labels})
% nb_freqs          - size of freqs vector.
%
% Author: Alexandre Delaux, 2020

nb_freqs = numel(freq_labels);
nb_chans = numel(chan_labels);
[Chan_inds,Freq_inds] = ind2sub([nb_chans, nb_freqs], OrderInd);

switch max_feat
    case 'all'
        max_feat=numel(scoreOfFeatures);
        TITLE=['Visualisation of all features according to fisher score'];
    otherwise
        TITLE=['Visualisation of the ', num2str(max_feat),' best features according to fisher score'];
end

data2plot=zeros(nb_chans, nb_freqs);
for i=1:max_feat
    data2plot(Chan_inds(i), Freq_inds(i))=scoreOfFeatures(i);
end

if nb_chans > 10
    for i=1:nb_chans
        if rem(i,2)==0
            chan_labels{i}=[chan_labels{i},'-------'];
        end
    end
end

figure
imagesc(data2plot)
xlabel('Frequency [Hz]')
if nb_freqs <= 5
    xticks(1:nb_freqs)
    xticklabels(freq_labels)
elseif nb_freqs <= 20
    xticks(1:2:nb_freqs)
    xticklabels(freq_labels(1:2:end))
else
    xticks(1:5:nb_freqs)
    xticklabels(freq_labels(1:5:end))
end
ylabel('Channel')
yticks(1:nb_chans)
yticklabels(chan_labels)
c=colorbar();
c.Label.String='Fisher score';
c.Label.FontSize=12;
title(TITLE)
set(gca, 'Fontsize', 12)
end