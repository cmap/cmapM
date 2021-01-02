function [pvalue,regulation,obsStat] = updateMarkers(ge,cls,drop,ref)
% UPDATEMARKERS  Subroutine for finding up/down regulated gene sets 
%   [pvalue,regulation,obsStat] = updateMarkers(ge,cls,drop,ref)
%   will run a monte carlo based permutation test to find the set
%   of differentially expressed gene sets. The pvalue is found via
%   many, default 1000, random rearrangments of the classes. Gene
%   sets can be found via pvalue and regulation indicator (i.e. +1
%   or -1) .
%   Inputs:
%      ge - an n by p data matrix.
%      cls - a structure with fields 'labels' and
%      'num_classes'. The cls.labels cell array specifies the
%      sample class membership. 
%      drop - an integer specifying the sample to drop, used when
%      running leave-one out biomarker selection. 
%      ref - a string which specifies the class to check for
%      enrichment. i.e. +1 implies upregulation in class 'ref'. By
%      default, the first class id that appears in the cls.labels
%      cell array will be the ref. This choice is arbitrary. 
%   Outputs: 
%      pvalue - a 1 by p vector of p-values. A pvalue is found for
%      each variable in ge, which tests for differential
%      expression. Direction of fold changes is indicated in
%      'regulation'. P-values are obtained from the ECDF of the
%      monte carlo permutation test statistics . 
%      regulation - a 1 by p vector with elements +1 or -1 which
%      indicate up or down regulation in the class 'ref'. 
%      obsStat - a 1 by p vector of the observed fold changes,
%      i.e. signal to noise ratio, for each gene. 
%
%   Note: This is a subroutine called by biomarker selection code
% 
%   See also conbiomarker, permutationtest, multibiomarker
% 
% Author: Brian Geier, Broad 2010  

cls.labels(drop) = [];
phenos = unique_ord(cls.labels); 

if nargin == 3
    ref = phenos{1}; 
end

if strcmp(ref,phenos{1})
    class1 = strcmp(phenos{1},cls.labels); 
    class2 = strcmp(phenos{2},cls.labels); 
elseif strcmp(ref,phenos{2})
    class1 = strcmp(phenos{2},cls.labels); 
    class2 = strcmp(phenos{1},cls.labels); 
else
    error('ref incorrect')
end
[pvalue,obsStat] = permutationtest(ge(class1,:),ge(class2,:),0); 
regulation = zeros(size(pvalue)); 
regulation(obsStat<0) = -1; 
regulation(obsStat>0) = 1; 