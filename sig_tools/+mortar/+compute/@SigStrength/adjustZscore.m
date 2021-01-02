function zs = adjustZscore(zs, nrep)
% ADJUSTZSCORE Adjust mod-zs values by the number of replicates.
% ADJZS = ADJUSTZSCORE(ZS, N) adjusts z-scores ZS using
% ADJZS = ZS * sqrt(N)

nrep = nrep(:)';

assert(isequal(size(zs, 2), length(nrep)),...
    'Length of nrep must equal the number of columns in ZS');
assert(all(nrep>=0), 'nrep must be >= 0');
zs = bsxfun(@times, zs, sqrt(nrep));

end