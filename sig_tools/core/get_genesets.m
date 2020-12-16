function [up, dn, to_keep] = get_genesets(ds, ngene, sortorder, varargin)
% GET_GENESETS Create genesets from a score matrix.
%   [UP, DN, TF] = GET_GENESETS(DS, N, SORTORDER) Returns the top N and
%   bottom N genesets for the score dataset DS sorted according to
%   SORTORDER. SORTORDER can be 'descend' or 'ascend'. UP and DN are
%   structures with length equal to the number of columns in DS. TF is a
%   boolean vector of same number of columns in DS that is true if a set
%   was generated from the column and false if it did not yield a set (if
%   for example the set was filtered based on minimum set size)
%
%   Each row in the structure has the the following fields:
%   hd : String header, same as the column id in DS with either '_UP' or
%       '_DN' appended.
%   desc :  String descriptor. Set to ''.
%   entry : Cell array of N row identifiers in DS.
%
%   [UP, DN] = GET_GENESETS(DS, N, SORTORDER, PARAM1, VALUE1) Specify
%   optional parameters:
%   'es_tail'   : String, specifies which tail to return.
%                 Can be {'both', 'up', 'down'}. Default is 'both'
%   'id_field'  : String, specifies an alternate metadata field to use for
%                 selecting features instead of ids. Default is '_id'
%   'desc_field'  : String, specifies a metadata field to use for
%                 the output desc field. Default is ''
%   'suffix'    : String, Append string to each set name. Default is none.
%   'dim'       : String, Dimension of matrix to operate on.
%                 Can be {'column', 'row'}. Default is to operate on
%                 'column' and return row-ids as sets
%   'enforce_set_size' : Boolean, Assert if set sizes match N exactly.
%                 A set size of less than N can result in cases where an
%                 alternate id_field is specified and there are duplicate
%                 entries. Set to false to disable this constraint. Default
%                 is true.
%   'min_set_size' : integer, minimum set size. Sets with fewer members are
%   excluded from the ouput. 
pnames = {'es_tail', 'suffix', 'id_field',...
    'dim', 'enforce_set_size', 'desc_field', 'min_set_size'};
dflts = {'both', '', '_id',...
    'column', true, '', 0};
args = parse_args(pnames, dflts, varargin{:});

ds = parse_gctx(ds);
[dim_str, dim_val] = get_dim2d(args.dim);
if isequal(dim_str, 'row')
    ds = transpose_gct(ds);
end

[nr, nc] = size(ds.mat);

% check if there are enough features
if isequal(args.es_tail, 'both')
    assert(nr>=2*ngene, ...
        'There are only %d features, cannot select 2x%d sized sets',...
        nr, ngene);
else
    assert(nr>=ngene, ...
        'There are only %d features, cannot select 1x%d sized sets',...
        nr, ngene);
end

[srtval, srtidx] = sort(ds.mat, sortorder);
is_nan_val = isnan(srtval);
has_nan = any(is_nan_val(:));

if all(ds.cdict.isKey(args.desc_field))
    desc = get_groupvar(ds.cdesc, ds.chd, args.desc_field);
elseif all(ismember({'pert_desc', 'pert_type'}, ds.chd))
    % These are espresso defaults but should be deprecated
    desc = strcat('desc:', ds.cdesc(:, ds.cdict('pert_desc')));
    desc = strcat(desc, ' type:', ds.cdesc(:, ds.cdict('pert_type')));
    if isKey(ds.cdict, 'distil_nsample')
        desc = strcat(desc, ' n:', num2cellstr(cell2mat(ds.cdesc(:, ds.cdict('distil_nsample')))));
    end
    if isKey(ds.cdict, 'islmark')
        desc = strcat(desc, ' lmark:', num2cellstr(cell2mat(ds.cdesc(:, ds.cdict('islmark')))));
    end
else
    desc = cell(nc, 1);
    [desc(:)] = {''};
end

if isempty(args.suffix)
    set_name = ds.cid;
else
    set_name = strcat(ds.cid, '_', args.suffix);
end

ids = ds_get_meta(ds,'row', args.id_field);
% check for duplicate ids
dup_ids = duplicates(ids);
has_dup_ids = ~isempty(dup_ids);
if has_dup_ids && args.enforce_set_size
    error(['ID field %s has %d duplicate entries listed above. ',...
        'Specify enforce_set_size to adjust this constraint'],...
        args.id_field, length(dup_ids));
end

up = struct('head', strcat(set_name, '_UP'),...
    'desc', desc,...
    'entry','',...
    'len', 0);

dn = struct('head', strcat(set_name, '_DN'),...
    'desc', desc,...
    'entry','',...
    'len', 0);

for ii=1:nc
    if ~has_nan
        keep_idx = srtidx(:, ii);
        set_size = ngene;
    else
        keep_idx = srtidx(~is_nan_val(:, ii), ii);
        n_not_nan = length(keep_idx);
        set_size = min(ngene, n_not_nan);
    end
    if set_size >= args.min_set_size
        switch(lower(args.es_tail))
            case 'both'
                up(ii).entry = get_ids(ids, keep_idx(1:set_size), has_dup_ids);
                dn(ii).entry = get_ids(ids, keep_idx(end-set_size+1:end), has_dup_ids);
                up(ii).len = set_size;
                dn(ii).len = set_size;
            case 'up'
                up(ii).entry = get_ids(ids, keep_idx(1:set_size), has_dup_ids);
                up(ii).len = set_size;
            case 'down'
                dn(ii).entry = get_ids(ids, keep_idx(end-set_size+1:end), has_dup_ids);
                dn(ii).len = set_size;
            otherwise
                error('Invalid es_tail, expected {both, up, down}, got %s', es_tail);
        end
    else
        dbg(1, 'Set %s has fewer than %d members, skipping', set_name{ii}, args.min_set_size);
    end
end

if isequal(args.es_tail, 'up')
    to_keep = [up.len]'>0;
    up = up(to_keep);
    dn = struct([]);
end

if isequal(args.es_tail, 'down')
    to_keep = [dn.len]'>0;
    dn = dn(to_keep);
    up = struct([]);
end

if isequal(args.es_tail, 'both')
    to_keep = [up.len]'>0 | [dn.len]'>0;
    up = up(to_keep);
    dn = dn(to_keep);
end

if ~all(to_keep)
    nexclude = nnz(~to_keep);
    disp(set_name(~to_keep));
    warning('%d sets were filtered due because they had fewer than %d members',...
        nexclude, args.min_set_size);
end

end

function res = get_ids(ids, idx, make_unique)
res = ids(idx);
if make_unique
    res = unique(res, 'stable');
end
end