function [cm,mcr,tpr] = run_method(ge,cls,method)
% RUN_METHOD  Routine for running classification method 
%   [cm,mcr,tpr] = run_method(ge,cls,m ethod) will run the
%   classification method 'method' given data ge and class
%   membership variable 'cls'. This is a subroutine called by
%   compareClassification. 
%   Inputs:
%      ge - an n by p data matrix.
%      cls - a structure with fields 'labels' and
%      'num_classes'. The cls.labels cell array specifies the
%      sample class membership. 
%      method - a string array which specifies the classification
%      method to use. Currently supported : 'knn-classify', 'svm',
%      'lda' (Linear discriminant), 'qda' (quadratic discriminant), 
%      'bayes' (naive bayes)
%   Outputs: 
%      cm - a confusion matrix, num_classes by num_classes
%      mcr - the miss-classification rate
%      tpr - the true positive classification rate
%      The confusion matrix, miss-classification rate, and true
%      positive rate are all found via 5-fold cross validation,
%      i.e. 5 independent random training/test splits. 
%
%   Note: This is a subroutine called by compareClassification
%   See also compareClassification, cvpartition, svmMethod,
%   knnclassify, classify, bayesMethod, evalconfmat. 
% 
% Author: Brian Geier, Broad 2010  

spopen ; 
opts = statset('UseParallel','always'); 
order = unique_ord(cls.labels); 
cp = cvpartition(cls.labels,'k',5);

fprintf(1,'%s\n',horzcat('Building ',method,' classifier...')); 
switch method
   
    case 'knn-classify'
        f = @(xtr,ytr,xte,yte) confusionmat(yte,...
            knnclassify(xte,xtr,ytr,1,'correlation'),'order',order);
        fprintf(1,'%s\n','Getting Confusion Matrix..');
        cm = crossval(f,ge,cls.labels,'partition',cp,'options',opts);
        cm = reshape(sum(cm),cls.num_classes,cls.num_classes); 
        [tpr,mcr] = evalconfmat(cm); 
    case 'svm'
        f = @(xtr,ytr,xte,yte) confusionmat(yte,...
            svmMethod(xte,xtr,ytr),'order',order);
        fprintf(1,'%s\n','Getting Confusion Matrix..');
        cm = crossval(f,ge,cls.labels,'partition',cp,'options',opts);
        cm = reshape(sum(cm),cls.num_classes,cls.num_classes); 
        [tpr,mcr] = evalconfmat(cm); 
    case 'lda'
        f = @(xtr,ytr,xte,yte) confusionmat(yte,...
            classify(xte,xtr,ytr,'diagLinear'),'order',order);
        fprintf(1,'%s\n','Getting Confusion Matrix..');
        cm = crossval(f,ge,cls.labels,'partition',cp,'options',opts);
        cm = reshape(sum(cm),cls.num_classes,cls.num_classes); 
        [tpr,mcr] = evalconfmat(cm); 
    case 'qda'
        f = @(xtr,ytr,xte,yte) confusionmat(yte,...
            classify(xte,xtr,ytr,'diagQuadratic'),'order',order);
        fprintf(1,'%s\n','Getting Confusion Matrix..');
        cm = crossval(f,ge,cls.labels,'partition',cp,'options',opts);
        cm = reshape(sum(cm),cls.num_classes,cls.num_classes); 
        [tpr,mcr] = evalconfmat(cm);         
    case 'bayes'
        f = @(xtr,ytr,xte,yte) confusionmat(yte,...
            bayesMethod(xte,xtr,ytr),'order',order);
        fprintf(1,'%s\n','Getting Confusion Matrix..');
        cm = crossval(f,ge,cls.labels,'partition',cp,'options',opts);
        cm = reshape(sum(cm),cls.num_classes,cls.num_classes);
        [tpr,mcr] = evalconfmat(cm); 
    otherwise
        error('Unsupported Method')
end      