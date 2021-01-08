function outds = matchQuery(ds, dim, match_field, id_field)
% MATCHQUERY Match row and columns of a matrix based on meta data
% OUT = matchQuery(DS, DIM, MATCH_FIELD, ID_FIELD)
%

[dim_str, dim_val] = get_dim2d(dim);

% match field must exist in both dimensions
assert(all(ds.rdict.isKey(match_field), ds.cdict.isKey(match_field)),...
       'match field:%s must exist in both dimensions', match_field)

switch dim_str
    case 'column'
        % id_fields must exist
        assert(all(ds.rdict.isKey(id_field)),...
            'id_fields not found for rows: %s',...
            print_dlm_line(~id_field(ds.rdict.isKey(id_field))));
        % the grouping of match_field and id_field must be unique
        [gpv, gpn, ~, ~, gpsz] = get_groupvar(ds.rdesc, ds.rhd, ...
                                                        {id_field, ...
                            match_field}, 'no_space', true, 'case', ...
                                                        '');
        disp(gpn(gpsz>1));
        assert(isequal(numel(gpv), numel(gpn)),...
            'Grouping of match_field and id_field must be unique for rows');
        % Apply matching
         outds = ds_match_column_field(ds, match_field, id_field);
    case 'row'
        % id_fields must exist
        assert(all(ds.cdict.isKey(id_field)),...
            'id_fields not found for columns: %s',...
            print_dlm_line(~id_field(ds.cdict.isKey(id_field))));
        % the grouping of match_field and id_field must be unique
        [gpv, gpn,~, ~, gpsz] = get_groupvar(ds.cdesc, ds.chd, ...
                                                       {id_field, ...
                            match_field}, 'no_space', true, 'case', ...
                                                       '');
        disp(gpn(gpsz>1));
        assert(isequal(numel(gpv), numel(gpn)),...
            'Grouping of match_field and id_field must be unique for columns');
        % Apply matching
        outds = ds_match_row_field(ds, match_field, id_field);
end

end

function outds = ds_match_column_field(ds, match_field, id_field)
% match columns to rows
row_meta = gctmeta(ds, 'row');
col_meta = gctmeta(ds, 'column');

% rows grouped by id_field
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(row_meta, fieldnames(row_meta), ...
                                                  id_field, 'no_space', ...
                                                  true, 'case', '');
ngp = length(gpn);

[nr, nc] = size(ds.mat);

% Extract column match_field annotations
[~, cidx] = intersect_ord({col_meta.cid}, ds.cid);
% col_id = {col_meta(cidx).(id_field)}';
col_mid = {col_meta(cidx).(match_field)}';

% Extract row match_field annotations
[~, ridx] = intersect_ord({row_meta.rid}, ds.rid);
% row_id = {row_meta(ridx).(id_field)}';
row_mid = {row_meta(ridx).(match_field)}';

% source ids to match id lookups
% cid2mid = mortar.containers.Dict(ds.cid, col_mid);
% rid2mid = mortar.containers.Dict(ds.rid, row_mid);

% column id to column index lookup
cid2cidx = mortar.containers.Dict(ds.cid);

% source cell id to target column group
% cid2tgroup = mortar.containers.Dict(ds.cid, gpv(cidx));

% group to output row index
gpn2ridx = mortar.containers.Dict(gpn);

% output matrix
out = nan(ngp, nc);

% groups of column match_field
[cmn, cmi] = getcls(col_mid);

nm = length(cmn);
for ii = 1:nm
    % columns corresponding to a given match_field member
    this_cidx = cmi == ii;
    % rows corresponding to match_field
    this_ridx = find(strcmp(row_mid, cmn{ii}));
    if ~isempty(this_ridx)
        out_ridx = gpn2ridx(gpv(this_ridx));
        out(out_ridx, cid2cidx(ds.cid(this_cidx))) = ds.mat(this_ridx, this_cidx);
    end
end

% row annotations for output
[~, uidx] = unique(gpi);
outmeta = row_meta(uidx);
new_id = gpv(uidx);
[outmeta.rid] = new_id{:};
outmeta = mvfield(outmeta, 'rid', 'id');
outmeta = rmfield(outmeta, match_field);

% output dataset
outds = mkgctstruct(out, 'rid', gpn, 'cid', ds.cid,...
                    'chd', ds.chd, 'cdesc', ds.cdesc);
outds = annotate_ds(outds, outmeta, 'dim', 'row', 'keyfield', 'id');
outds = annotate_ds(outds, col_meta, 'dim', 'column', 'keyfield', 'cid');
outds = ds_delete_missing(outds);
end

function outds = ds_match_row_field(ds, match_field, id_field)
% match rows to columns
row_meta = gctmeta(ds, 'row');
col_meta = gctmeta(ds, 'column');

% columns grouped by id_field
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(col_meta, fieldnames(col_meta), ...
                                                  id_field, 'no_space', ...
                                                  true, 'case', '');
ngp = length(gpn);

[nr, nc] = size(ds.mat);

% Extract column match_field annotations
[~, cidx] = intersect_ord({col_meta.cid}, ds.cid);
% col_id = {col_meta(cidx).(id_field)}';
col_mid = {col_meta(cidx).(match_field)}';

% Extract target match_field annotations
[~, ridx] = intersect_ord({row_meta.rid}, ds.rid);
% row_id = {row_meta(ridx).(id_field)}';
row_mid = {row_meta(ridx).(match_field)}';

% source id (cid or rid) to match_field lookups
cid2mid = mortar.containers.Dict(ds.cid, col_mid);
rid2mid = mortar.containers.Dict(ds.rid, row_mid);

% row id to row index lookup
rid2ridx = mortar.containers.Dict(ds.rid);

% source cell id to target column group
cid2tgroup = mortar.containers.Dict(ds.cid, gpv(cidx));

% group to output column index
gpn2cidx = mortar.containers.Dict(gpn);

% output matrix
out = nan(nr, ngp);

% row_mid = rid2cellid(ds.rid);
[rmn, rmi] = getcls(row_mid);

nm = length(rmn);
for ii = 1:nm
    % targets corresponding to a given cell type
    this_ridx = rmi == ii;
    % columns corresponding to match_field
    this_cidx = find(strcmp(col_mid, rmn{ii}));
    if ~isempty(this_cidx)
        out_cidx = gpn2cidx(gpv(this_cidx));
        out(rid2ridx(ds.rid(this_ridx)), out_cidx) = ds.mat(this_ridx, this_cidx);
    end
end
                
% column annotations for output
[~, uidx] = unique(gpi);
outmeta = col_meta(uidx);
new_id = gpv(uidx);
[outmeta.cid] = new_id{:};
outmeta = mvfield(outmeta, 'cid', 'id');
outmeta = rmfield(outmeta, match_field);

% output dataset
outds = mkgctstruct(out, 'rid', ds.rid, 'cid', gpn,...
                    'rhd', ds.rhd, 'rdesc', ds.rdesc);
outds = annotate_ds(outds, outmeta, 'dim', 'column', 'keyfield', 'id');
outds = annotate_ds(outds, row_meta, 'dim', 'row', 'keyfield', 'rid');
outds = ds_delete_missing(outds);
end
