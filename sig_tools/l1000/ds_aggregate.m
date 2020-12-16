function ds = ds_aggregate(ds, varargin)
% DS_AGGREGATE Computes aggregate values for a dataset by specified
% grouping variable(s). 
%   ADS = DS_AGGREGATE(DS, 'param1', value1, ... )
% Takes in a dataset structure DS and returns a aggregate version ADS that
% has values aggregated by the by common values in the parameters. The
% following parameters are supported:
%
% PARAMETER     VALUE 
% 'row_fields'  cell array of values from ds.rhd to collapse
% 'col_fields'  cell array of values from ds.chd to collapse
% 'fun'         FUN can be a string or a function handle. The default
%               is 'mean'. See AGGREGATE_FUN for other options.
%               Custom aggregation functions can be specified as follows:
%               agg_fun = @(x, dim) myfun(x, dim)

pnames = {'row_fields', 'col_fields', 'fun', 'dlm', 'rows_first'};
dflts = {{}, {}, 'mean', ':', true};
args = parse_args(pnames, dflts, varargin{:});

if args.rows_first
    % aggregate rows first before columns
    if ~isempty(args.row_fields)
        hfun = aggregate_fun(args.fun, 1);
        ds = row_collapser(ds, args.row_fields, hfun, args);
    end
    
    if ~isempty(args.col_fields)
        hfun = aggregate_fun(args.fun, 2);
        ds = col_collapser(ds, args.col_fields, hfun, args);
    end
else
    % aggregate columns first before rows
    if ~isempty(args.col_fields)
        hfun = aggregate_fun(args.fun, 2);
        ds = col_collapser(ds, args.col_fields, hfun, args);
    end
    if ~isempty(args.row_fields)
        hfun = aggregate_fun(args.fun, 1);
        ds = row_collapser(ds, args.row_fields, hfun, args);
    end    
end

end

function ds = row_collapser(ds, row_fields, fun, args)
% Collapse rows and meta data

% get grouping variable
[gpv, gp, gpi, ~, gpsz] = get_groupvar(ds.rdesc, ds.rhd, row_fields,...
                                       'dlm', args.dlm);
nr = length(gp);
nc = size(ds.mat, 2);
mat = zeros(nr, nc);
rid = cell(nr, 1);
rdesc = cell(nr, size(ds.rdesc, 2));

% keep singletons as-is
is_singleton = ismember(gpi, find(gpsz<=1));
nsingle = nnz(is_singleton);
mat(1:nsingle, :) = ds.mat(is_singleton, :);
rid(1:nsingle) = gpv(is_singleton);
rdesc(1:nsingle, :) = ds.rdesc(is_singleton, :);

% aggregate reps
toagg = unique(gpi(~is_singleton));
nagg = length(toagg);
for ii=1:nagg
    ridx = ismember(gpi, toagg(ii));
    mat(nsingle+ii, :) = feval(fun, ds.mat(ridx, :), 1);
    rid(nsingle+ii) = gp(toagg(ii));
    rdesc(nsingle+ii, :) = aggregate_meta(ds.rdesc, ridx);
end

ds = mkgctstruct(mat, 'rid', rid, 'rhd', ds.rhd, 'rdesc', rdesc,...
                'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc); 
% Add number of elements aggregated            
[c, ia, ib] = intersect(rid, gp, 'stable');            
ds = ds_add_meta(ds, 'row', 'num_agg', num2cell(gpsz(ib)));

end

function ds = col_collapser(ds, col_fields, fun, args)
% Collapse columns and meta data

% get grouping variable
[gpv, gp, gpi, ~, gpsz] = get_groupvar(ds.cdesc, ds.chd, col_fields,...
                          'dlm', args.dlm);
nr = size(ds.mat, 1);
nc = length(gp);
mat = zeros(nr, nc);
cid = cell(nc, 1);
cdesc = cell(nc, size(ds.cdesc, 2));

% keep singletons as-is
is_singleton = ismember(gpi, find(gpsz<=1));
nsingle = nnz(is_singleton);
mat(:, 1:nsingle) = ds.mat(:, is_singleton);
cid(1:nsingle) = gpv(is_singleton);
cdesc(1:nsingle, :) = ds.cdesc(is_singleton, :);

% aggregate reps
toagg = unique(gpi(~is_singleton));
nagg = length(toagg);
for ii=1:nagg
    cidx = ismember(gpi, toagg(ii));
    mat(:, nsingle+ii) = feval(fun, ds.mat(:, cidx), 2);
    cid(nsingle+ii) = gp(toagg(ii));
    cdesc(nsingle+ii, :) = aggregate_meta(ds.cdesc, cidx);
end

ds = mkgctstruct(mat, 'rid', ds.rid, 'rhd', ds.rhd, 'rdesc', ds.rdesc,...
                'cid', cid, 'chd', ds.chd, 'cdesc', cdesc);
% Add number of elements aggregated
[~, ~, ib] = intersect(cid, gp, 'stable');                        
ds = ds_add_meta(ds, 'column', 'num_agg', num2cell(gpsz(ib)));
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