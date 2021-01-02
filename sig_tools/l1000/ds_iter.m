function [ds, cur] = ds_iter(ds, block_size, last_cur, varargin)
% DS_ITER helper function to iterate over a large data set. 
%
% [DS, CUR] = DS_ITER(DSFILE, N, LAST) returns a subset of N columns from
% the dataset DSFILE starting from the index specified in LAST. LAST is a
% cursor structure returned by the function. If LAST is empty the first N
% columns are returned.
% 
% DS_ITER(..., 'PARAM1', VAL1, 'PARAM2', VAL2) specifiy additional
% parameters and their values. Valid parameters are the following:
%
%       Parameter        Value
%       'dim'           'column' (the default) to iterate over columns, 
%                       'row' to iterate over rows.
%       'rid'           '' (default) cell array of row ids. When iterating
%                       over columns returns a dataset containing only
%                       these rows. When iterating over rows only iterate
%                       over these rows.
%       'cid'           '' (default), cell array of column ids. Function is
%                       similar to 'rid'
%       'start_index'   1 (default), start iterating at the given index.
%
% Use this function to iterate over a large dataset using the
% following pattern:
%
% [DS, CUR] = DS_ITER(DSFILE, N, '')
% while ~isempty(DS)
%   % do something with DS
%   [DS, CUR] = DS_ITER(DSFILE, N, CUR)
% end

pnames = {'dim', 'rid', 'cid', 'start_index', 'matrix_class'};
dflts = {'column', '', '', 1, ''};
args = parse_args(pnames, dflts, varargin{:});

if isempty(last_cur)    
    annot = parse_gctx(ds, 'annot_only', true);
    idx_start = args.start_index;    
    if ~isempty(args.rid)
        rid = intersect_ord(annot.rid, args.rid);
        assert(isequal(numel(rid), numel(args.rid)), 'Some features not found');
    else
        rid = annot.rid;
    end
    
    if ~isempty(args.cid)
        cid = intersect_ord(annot.cid, args.cid);
        assert(isequal(numel(cid), numel(args.cid)), 'Some columns not found');
    else
        cid = annot.cid;
    end
    nr = length(rid);
    nc = length(cid);
    switch (args.dim)
        case {'column'}
            max_idx = nc;
        case 'row'
            max_idx = nr;
        otherwise
            error('Invalid dimension: %s , must be either ''row'' or ''column''', args.dim);
    end    
    idx_stop = min(block_size, max_idx);
        
    cur = struct('ds', ds,...
        'idx_start', idx_start,...
        'idx_stop', idx_stop,...
        'max_idx', max_idx,...
        'nr', nr,...
        'nc', nc,...
        'dim', args.dim,...
        'rid', {rid},...
        'cid', {cid});
else    
    cur = last_cur;
    cur.idx_start = cur.idx_stop + 1;
    cur.idx_stop = min(cur.idx_start + block_size - 1, cur.max_idx);
end
if ischar(cur.ds)
    assert(isequal(ds, cur.ds), 'ds file does not match cur');
end
if cur.idx_start <= cur.max_idx    
    if isequal(cur.dim, 'column')
        ds = parse_gctx(ds, 'rid', cur.rid,...
                'cid', cur.cid(cur.idx_start:cur.idx_stop),...
                'matrix_class', args.matrix_class);
    else
        ds = parse_gctx(ds, 'cid', cur.cid, 'rid',...
                cur.rid(cur.idx_start:cur.idx_stop),...
                'matrix_class', args.matrix_class);
    end
else
    ds = [];
    cur = [];
end

end