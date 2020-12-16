function [tpr,mcr] = evalconfmat(confmat) 
% EVALCONFMAT Evaluates the confusion matrix
%  [tpr,mcr] = evalconfmat(confmat) will return the true positive
%  rate and missclassification rate given an observed hypothesis
%  table
% see also run_method

priors = sum(confmat,2)/sum(confmat(:)); 
tpr = (diag(confmat)./sum(confmat,2))'*priors ; 
idx = logical(eye(size(confmat,2))); 

mcr = (sum(reshape(confmat(~idx),[size(confmat,1)-1,size(confmat,2)]))./...
    sum(confmat))*priors ; 