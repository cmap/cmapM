function class = svmMethod(xte,xtr,ytr)
% SVMMETHOD  Subroutine for running SVM 
%   class = svmMethod(xte,xtr,ytr) will build a SVM classify object
%   with xtr (covariates) ytr (class membership) and will predict
%   the membership of each xte (unobserved covariate samples).  
%   Inputs:  
%      xtr - an n by p data matrix. The covariate space for
%      training the classifier object. 
%      ytr - an n by 1 cell array specifying the class membership
%      of each sample
%      xte - an m by p data matrix. The covariate space for
%      validating the trained classifier object. 
%   Outputs: 
%      class - an n by 1 cell array specifying class predictions
%      given (xtr,ytr) SVM object. 
%
%   Note: This is a subroutine called by run_method
%   See also compareClassification, run_method
% 
% Author: Brian Geier, Broad 2010  

class = svmclassify(svmtrain(xtr,ytr),xte); 