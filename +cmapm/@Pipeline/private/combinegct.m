function c = combinegct(b, varargin)
% COMBINEGCT Combine beadset-level plates

pnames = {'keepshared'};
dflts = {true};
arg = parse_args(pnames, dflts, varargin{:});

if ~isequal(length(b),2)
    error('Input should include two datasets');
end

% features not assigned NA
naidx1 = strcmp('NOT_ASSIGNED', b(1).rid);
naidx2 = strcmp('NOT_ASSIGNED', b(2).rid);
na1 = b(1).rid(naidx1);
na2 = b(2).rid(naidx2);
% shared features excluding NA's
[dups, gidx1, gidx2] = intersect(setdiff(b(1).rid, na1), setdiff(b(2).rid, na2));

% unique features
[ugn1, uidx1] = setdiff(b(1).rid, union(dups, na1));
% maintain original ordering
[ugn1, uidx1] = sortidx(ugn1, uidx1);

[ugn2, uidx2] = setdiff(b(2).rid, union(dups, na2));
[ugn2, uidx2] = sortidx(ugn2, uidx2);

nc = length(b(1).cid);
if arg.keepshared
    % include shared features
    rid = [dups; ugn1; ugn2];
    rdesc = [b(1).rdesc(gidx1,:); b(1).rdesc(uidx1, :); b(2).rdesc(uidx2, :)];
    nr = length(rid);
    nshared = length(dups);
    mat = zeros(nr, nc, 'single');
    mat(1:nshared,:) = 0.5*(b(1).mat(gidx1,:) +  b(2).mat(gidx2,:));
    mat(nshared+(1:length(uidx1)),:) = b(1).mat(uidx1,:);
    mat(nshared+length(uidx1)+(1:length(uidx2)),:) = b(2).mat(uidx2,:);    
else
    % exclude shared features
    rid = [ugn1; ugn2];
    rdesc = [b(1).rdesc(uidx1,:); b(2).rdesc(uidx2,:)];
    nr = length(rid);    
    mat = zeros(nr, nc, 'single');
    mat(1:length(uidx1), :) = b(1).mat(uidx1,:);
    mat(length(uidx1)+(1:length(uidx2)), :) = b(2).mat(uidx2,:);
end

c = mkgctstruct(mat, 'rid', rid, 'rhd', b(1).rhd, 'rdesc', rdesc,...
    'cid', b(1).cid, 'chd', b(1).chd, 'cdesc', b(1).cdesc);

% sort features
c = sort_features(c);

end

% sort by index
function [srtx, srtidx] = sortidx(x, idx)
[srtidx, si] = sort(idx);
srtx = x(si);
end
