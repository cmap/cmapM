function ss = sig_strength(x, varargin)
% SIG_STRENGTH Compute signature strength.
%   SS = SIG_STRENGTH(X) Computes the signature strength for each column in
%   the z-score data matrix X. The signature strength is computed as:
%   mean(zscores of top N features) - mean(zscores of bottom N features)
%   The number of features N = 50 by default.
%   SS = SIG_STRENGTH(X, 'n', N) Specifies N

pnames = {'n'};
dflts = {50};
args = parse_args(pnames, dflts, varargin{:});
srtx = sort(x, 'descend');
ss = (mean(srtx(1:args.n, :), 1) - mean(srtx(end-args.n+1:end, :), 1))';
end