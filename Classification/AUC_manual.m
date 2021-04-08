function [ AUC ] = AUC_manual(fpr, tpr)
% Author: Alexandre Delaux, 2020

h=tpr(1:end-1)+tpr(2:end);
w=diff(fpr);
AUC=sum(h.*w)/2;
end

