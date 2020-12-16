function [ntot, nup, ndn] = ssNgene(x, varargin)
% ssNgene Compute signature strength based on number of induced features.
%   [NTOT, NUP, NDN] = ssNgene(X) Computes the signature strength for each column in
%   the z-score data matrix X. The signature strength is computed as:
%   NUP = Number of rows in X >= C
%   NDN = Number of rows in X <= -C
%   NTOT = NUP + NDN
%
%   SS = ssNgene(X, 'cutoff', 2) Specifies the cutoff C, which is 2 by
%   default

pnames = {'cutoff'};
dflts = {2};
args = parse_args(pnames, dflts, varargin{:});

nup = sum(x >= args.cutoff, 1)';
ndn = sum(x <= -args.cutoff, 1)';
ntot = nup + ndn;

end

