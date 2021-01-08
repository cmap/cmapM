function ds = ds_aggregate_set(ds, pcl_file, varargin)
% DS_AGGREGATE Computes aggregate values for a dataset by specified
% grouping variable(s). 
%   ADS = DS_AGGREGATE(DS, PCL_FILE, 'param1', value1, ... )
% Takes in a dataset structure DS and returns a aggregate version ADS that
% has values aggregated by the by sets defined in the PCL_FILE GMT. The
% following parameters are supported:
%
% PARAMETER     VALUE 
% 'fun'         FUN can be a string or a function handle. The default
%               is 'mean'. See AGGREGATE_FUN for other options.
%               Custom aggregation functions can be specified as follows:
%               agg_fun = @(x, dim) myfun(x, dim)

pnames = {'fun', 'dlm', 'rows_first', 'min_size', 'match_field'};
dflts = {'mean', ':', true, 0, 'pert_iname'};
args = parse_args(pnames, dflts, varargin{:});
match_field = args.match_field;

if ~isempty(pcl_file)
    pcls = parse_geneset(pcl_file);
end

%filter by min_size
pcls = pcls([pcls.len] >= args.min_size);

if args.rows_first
    % aggregate rows first before columns
    hfun = aggregate_fun(args.fun, 1);
    ds = row_collapser_gmt(ds, pcls, hfun, match_field);
    
    hfun = aggregate_fun(args.fun, 2);
    ds = col_collapser_gmt(ds, pcls, hfun, match_field);
else
    % aggregate columns first before rows
    hfun = aggregate_fun(args.fun, 2);
    ds = col_collapser_gmt(ds, pcls, hfun, match_field);

    hfun = aggregate_fun(args.fun, 1);
    ds = row_collapser_gmt(ds, pcls, hfun, match_field);
end

end

%% Row Collapser
function ds = row_collapser_gmt(ds, pcls, fun, match_field)

meta = gctmeta(ds, 'row');
            
nr = length(pcls);
nc = size(ds.mat, 2);
mat = zeros(nr, nc);
rid = {pcls.head};
rdesc = cell(nr, size(ds.rdesc, 2));

set_size = nan(nr, 1);
for ii = 1:numel(pcls)
    idx = ismember({meta.(match_field)}, pcls(ii).entry);
    mat(ii,:) = feval(fun, ds.mat(idx,:), 1);
    rdesc(ii, :) = aggregate_meta(ds.rdesc, idx);
    set_size(ii) = nnz(idx);
end

ds = mkgctstruct(mat, 'rid', rid, 'rhd', ds.rhd, 'rdesc', rdesc,...
                'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc); 
ds = ds_add_meta(ds, 'row', 'set_id', rid');
ds = ds_add_meta(ds, 'row', 'set_agg', num2cell(set_size));
end

%% Column Collapser
function ds = col_collapser_gmt(ds, pcls, fun, match_field)

meta = gctmeta(ds);

nr = size(ds.mat, 1);
nc = length(pcls);
mat = zeros(nr, nc);
cid = cell(nc, 1);
cdesc = cell(nc, size(ds.cdesc, 2));

cid = {pcls.head};

set_size = nan(nc, 1);

for ii = 1:numel(pcls)
    idx = ismember({meta.(match_field)}, pcls(ii).entry);
    mat(:,ii) = feval(fun, ds.mat(:,idx), 2);
    cdesc(ii, :) = aggregate_meta(ds.cdesc, idx);
    set_size(ii) = nnz(idx); 
end

ds = mkgctstruct(mat, 'rid', ds.rid, 'rhd', ds.rhd, 'rdesc', ds.rdesc,...
                'cid', cid, 'chd', ds.chd, 'cdesc', cdesc);
ds = ds_add_meta(ds, 'column', 'set_id', cid');
ds = ds_add_meta(ds, 'column', 'set_size', num2cell(set_size));
end

function meta = aggregate_meta(desc, ridx)
[~, nc] = size(desc);
meta = cell(1, nc);
for ii=1:nc
    d = desc(ridx, ii);
    isnum = isnumeric_type(d);
    if any(isnum)
        d = cell2mat(d);
    end
    meta{ii} = print_dlm_line(unique(d, 'stable'), 'dlm', '|');    
end
end