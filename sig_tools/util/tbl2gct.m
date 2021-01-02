function gct = tbl2gct(tbl, cid_field, rid_field)
% TBL2GCT Convert TBL structure to GCT structure.
%   GCT = TBL2GCT(TBL, CID_FIELD, RID_FIELD)

if isfileexist(tbl)
    tbl = parse_tbl(tbl, 'outfmt', 'record');
end

fn = fieldnames(tbl);
c = struct2cell(tbl)';
% row id field
rid = get_groupvar(tbl, [], rid_field);
ridx = find(ismember(fn, rid_field));
%assert(isequal(numel(ridx), 1), 'Expected 1 row id field found %d',...
%       numel(ridx));

% column id fields (matrix fields)
cidx = find(ismember(fn, cid_field));
assert(numel(cidx)>0, 'Expected at least 1 column id field found %d', numel(cidx));

% all other fields are row descriptors
rdescidx = setdiff(1:length(fn), union(ridx, cidx));

gct = mkgctstruct(cell2mat(c(:, cidx)), 'cid', fn(cidx), 'rid', rid,...
                'rhd', fn(rdescidx), 'rdesc', c(:, rdescidx));

end