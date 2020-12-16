function idx = grpsize2idx(sz, vals)
% GRPSIZE2IDX Generate index vector from a list of grou sizes
%   IDX = GRPSIZE2IDX(SZ) returns an index vector given group sizes SZ. The
%   length of IDX is equal to sum(SZ) with the indices ranging from
%   1:length(SZ). SZ elements that are NaNs or values less than 1 are
%   ignored and the indices corresponding to those elements are skipped.
%
%   IDX = GRPSIZE2IDX(SZ, V) uses V as the indices. The length of V should
%   equal the number of groups.
%
%   Examples
%   sz = [2; 4; 0; 3];
%   vals = [10; 15; -10; 5];
%   idx = grpsize2idx(sz, vals)


if ~isvarexist('vals')
    vals = (1:length(sz))';
else
    vals = vals(:);
end
sz = sz(:);
% handle missing / zero sized groups
isnz = sz>0 & ~isnan(sz);
sz = sz(isnz);

vals = vals(isnz);
assert(isvector(sz), 'SZ should be a 1d vector');
assert(isvector(vals), 'VALS should be a 1d vector');
assert(isequal(length(sz), length(vals)),...
    'Length of SZ (%d) must equal V (%d)', length(sz), length(vals));
uv = unique(vals);
assert(isequal(length(uv), length(vals)),...
    'VALS should be unique');

d = diff([0; vals]);
csz = cumsum([1; sz]);
nmember = csz(end)-1;
idx = zeros(nmember, 1);
idx(csz(1:end-1)) = d;
idx = cumsum(idx);

end