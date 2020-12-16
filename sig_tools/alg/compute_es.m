function [es, hitrank, hitind, esmax] = compute_es(gset, li, gn, varargin)
% ES Compute Enrichment score 
%   [ES, HITRANK, HITIND] = COMPUTE_ES(GSET,LI,GN)
%
%   Inputs:
%   GSET    List of labels to test for enrichment specified in GN 
%           [Gx1 cellstr array], OR a vector of indices of GN
%   LI      unsorted list of values in which to test for enrichment
%           [N x C matrix]
%   GN      Labels of rows in LI. Not used if GSET is a vector.
%
%   Outputs:
%   ES         Running Enrichment scores for each column in LI [N x C
%              double array]
%   HITRANK    Rank of each hit 
%   HITIND     Indices of GN for each element of GSET in GN (Gx1 vector)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Nov.12.2007 12:01:45 EDT
% Changes: 12/12/2008 added to BMTK

nargs = nargin;

pnames = {'weight', 'exponent', 'isranked'};
valides = {'classic', 'weighted'};
dflts =  {'classic', 1, false};

%[eid, emsg, midx, weight, p, isranked] = getargs(pnames, dflts, varargin{:});
args = parse_args(pnames, dflts, varargin{:});

% check if valid es type
if ~isvalidstr(args.weight, valides)
    error('Invalid weight: %s\n', args.weight);
else
    isweighted = isequal(args.weight,'weighted');        
end

% Total number of genes(N) and instances(C) in cmap
[N,C] = size(li);

% geneset could be an array of indices or a celstr
if (iscell(gset))
    [cmn,hitind] = intersect_ord(gn,gset);
    if ~isequal(length(gset), length(cmn))
        disp('Some genes from set missing');
        disp(setdiff(gset,cmn));
    end
else
    hitind = gset;
end

% Number of genes in geneset present in dataset
G = numel(hitind);

% Enrichment scores (ES) for all instances
% Initialize ES to cost of a miss
es = ones(N,C).*(-1/(N-G));

% Get ranks
% Ranks of each hit for all instances
% Note: ensure ranks start at 1
if ~args.isranked
    rank = rankorder(li, 'direc','descend', 'zeroindex','false', 'fixties', false);
    hitrank = rank(hitind,:);
else
    %Note: keep hitranks as double to avoid overflow
    hitrank = double(li(hitind,:));
end

% Column indices of all instances for each gene
J = repmat(1:C,G,1);

% Mark hit indices with the cost of a hit
if isweighted
    % weighted ES score    
    x = abs(li(hitind,:)).^args.exponent;
    es(int64(hitrank+N*(J-1))) = x ./ repmat(sum(x, 1), G, 1);
else    
    % unweighted ES
    % note: exponent=0 will the give the same result
    es(int64(hitrank+N*(J-1))) = 1/G;
end

% Running Enrichment score
es = cumsum(es);
%up data
[esmax, ridx] = max(abs(es));
%restore the sign
esmax = esmax .* sign(es(ridx + N * (0:(C-1))));


