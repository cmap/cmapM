function [class,post] = bayesMethod(xte,xtr,ytr)
% BAYESMETHOD  Subroutine for running naive bayes classifier 
%   class = bayesMethod(xte,xtr,ytr) will build a naive bayes
%   classify object with xtr (covariates) ytr (class membership)
%   and will predict the membership of each xte (unobserved covariate samples).  
%   Inputs:  
%      xtr - an n by p data matrix. The covariate space for
%      training the classifier object. 
%      ytr - an n by 1 cell array specifying the class membership
%      of each sample
%      xte - an m by p data matrix. The covariate space for
%      validating the trained classifier object. 
%   Outputs: 
%      class - an n by 1 cell array specifying class predictions
%      given (xtr,ytr) bayes object. 
%
%   Note: This is a subroutine called by run_method
%   See also compareClassification, run_method
% 
% Author: Brian Geier, Broad 2010  

obj = NaiveBayes.fit(xtr,ytr);%,'Distribution','kernel');
class = obj.predict(xte); 
post = posterior(obj,xte); 
