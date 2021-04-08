function [imposed_fpr, imposed_tpr] = uniform_ROC(fpr, tpr, nb_points)
% Changes the actual ROC evaluation to a standard one
%
% Author: Alexandre Delaux, 2020

imposed_fpr=0:1/nb_points:1;
imposed_tpr=zeros(1,nb_points);
for x=1:length(imposed_fpr)
    ind=max(find(fpr<=imposed_fpr(x)));
    imposed_tpr(x)=tpr(ind);
end
end

