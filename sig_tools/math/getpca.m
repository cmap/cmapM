function [pc,score,pcvar] = getpca(m, varargin)
% GETPCA Compute the principal components
% [PC,SCORE,PCVAR] = GETPCA(M) Returns the principal component coefficients 
% (PC), scores (SCORE) and variance (PCVAR) of matrix M. Rows of M 
% correspond to observations (eg instances), columns to variables (eg.
% features).
%
% To obtain percent of total variance explained:
% figure; 
% pareto(100*pcvar/sum(pcvar))

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

error(nargchk (1,3,nargin));

pnames = {'xform','isecon'};
dflts =  {'none', false };

args = parse_args(pnames, dflts, varargin{:});
if args.isecon
    econFlag='econ';
else
    econFlag=0;
end

% [pc,score,pcvar] =  princomp(m' - repmat(mean(m'),size(m,2),1));
% [pc,score,pcvar] =  princomp(m - repmat(mean(m),size(m,1),1));

switch(lower(args.xform))
    % PCA on standardized variables
    case 'zscore'
        
        [pc, score, pcvar] = princomp(zscore(m), econFlag);
        % PCA on mean centered variables
    case 'none'
        [pc, score, pcvar] = princomp(m, econFlag);
end
