function ds = ds_slice(ds, varargin)
% DS_SLICE Extract a subset of data from a GCT structure.
%   DS_SLICE(DS, 'param1', value1, ...)
%   Extracts a subset of data from GCT structure DS. The following
%   parameters are supported:
%       Parameter   Value
%       'rid'       List of row-ids to extract. Default is all row ids.
%       'cid'       List of column-ids to extract. Default is all column ids.
%       'exclude_rid'   Select row-ids excluding 'rid' if true. Default is false
%       'exclude_cid'   Select column-ids excluding 'cid' if true. Default is false
%       'ridx'      Array of row indices to extract.
%       'cidx'      Array of column indices to extract.
%       'ignore_missing'    Ignore missing ids if true. Default is false.
%       'isverbose' Verbosity. Default is true.

% pnames = {'rid', 'ridx', 'cid',...
%           'cidx','exclude_rid', 'exclude_cid',...
%           'ignore_missing', 'isverbose', 'row_field', 'column_field'};
% dflts = {'', [], '',...
%          [], false, false,...
%          false, true, '', ''};
% args = parse_args(pnames, dflts, varargin{:});
% config = struct('name', {'--rid';'--ridx';...
%     '--cid';'--cidx';...
%     '--exclude_rid'; '--exclude_cid';...
%     '--ignore_missing'; '--isverbose';...
%     '--row_field'; '--column_field';...
%     '--checkid';...
%     },...
%     'default', {''; [];...
%     ''; [];...
%     false; false;...
%     false; true;...
%     ''; '';...
%     true},...
%     'help', {'List of row-ids to extract'; 'Array of row indices to extract';...
%     'List of column-ids to extract'; 'Array of column indices to extract';...
%     'Select row-ids excluding rid if true'; 'Select column-ids excluding cid if true';...
%     'Ignore missing ids if true'; 'Verbosity of messages';...
%     'Alternate row metadata field to match'; 'Alternate column metadata field to match';...
%     'Check if row and column ids are unique'});
pnames = {'rid','ridx',...
    'cid','cidx',...
    'exclude_rid', 'exclude_cid',...
    'ignore_missing', 'isverbose',...
    'row_field', 'column_field',...
    'checkid',...
    };
dflts = {'', [],...
    '', [],...
    false, false,...
    false, true,...
    '', '',...
    true};

% opt = struct('prog', mfilename, 'desc', 'Extract a subset of data from a GCT structure.');
% args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
args = parse_args(pnames, dflts, varargin{:});
if (iscell(args.rid) || isfileexist(args.rid)) || ~isempty(args.ridx)
    if isempty(args.ridx)
        rspace = parse_grp(args.rid);
        if isempty(args.row_field)
            [rid, ridx] = subset(ds.rid, rspace, args.exclude_rid);
            has_missing = check_missing(ds.rid, rspace, rid, args.exclude_rid,...
                args.ignore_missing, args.isverbose, isempty(args.row_field));
        else
            rid_all = ds_get_meta(ds, 'row', args.row_field);
            if args.exclude_rid
                ridx = find(~ismember(rid_all, rspace));
            else
                ridx = find(ismember(rid_all, rspace));
            end
            rid = rid_all(ridx);
            has_missing = check_missing(rid_all, rspace, rid, args.exclude_rid,...
                args.ignore_missing, args.isverbose, isempty(args.row_field));
        end
    else
        ridx = args.ridx;
        has_missing = false;
    end
    
    if ~isempty(ridx)
        % subset gct to use
        if ~isempty(ds.mat)
            ds.mat = ds.mat(ridx, :);
        else
            ds.mat = [];
        end
        ds.rid = ds.rid(ridx);        
        if ~isempty(ds.rdesc)
            ds.rdesc = ds.rdesc(ridx, :);
        end
    elseif isempty(ridx) && has_missing
        ds = mkgctstruct([]);
    end
end

if (iscell(args.cid) || isfileexist(args.cid)) || ~isempty(args.cidx)
    if isempty(args.cidx)
        cspace = parse_grp(args.cid);
        if isempty(args.row_field)
            [cid, cidx] = subset(ds.cid, cspace, args.exclude_cid);
            has_missing = check_missing(ds.cid, cspace, cid, args.exclude_cid,...
                args.ignore_missing, args.isverbose,...
                isempty(args.column_field));
        else
            cid_all = ds_get_meta(ds, 'column', args.column_field);
            if args.exclude_cid
                cidx = find(~ismember(cid_all, cspace));
            else
                cidx = find(ismember(cid_all, cspace));
            end
            cid = cid_all(cidx);
            has_missing = check_missing(cid_all, cspace, cid, args.exclude_cid,...
                args.ignore_missing, args.isverbose,...
                isempty(args.column_field));
        end
    else
        cidx = args.cidx;
        has_missing = false;
    end
    
    if ~isempty(cidx)
        % subset gct to use
        if ~isempty(ds.mat)
            ds.mat = ds.mat(:, cidx);
        else
            ds.mat = [];
        end
        ds.cid = ds.cid(cidx);        
        if ~isempty(ds.cdesc)
            ds.cdesc = ds.cdesc(cidx, :);
        end
    elseif isempty(cidx) && has_missing
        ds = mkgctstruct([]);
    end
end
check_dup_id(ds.cid, args.checkid);
check_dup_id(ds.rid, args.checkid);
end

function has_missing = check_missing(universe, subspace, id,...
    exclude_flag, ignore_missing, isverbose,...
    is_id)
% check if all of the specified items were selected
has_missing = false;
if is_id
    if (~exclude_flag && ~isequal(length(subspace), length(id))) || ...
            (exclude_flag && ~isequal(length(subspace), length(universe) - length(id)))
        has_missing = true;
        if (ignore_missing && isverbose) || ~ignore_missing
            if exclude_flag
                disp(setdiff(union(subspace, id), universe))
            else
                dups = duplicates(subspace);
                if ~isempty(dups)
                    disp(dups)
                    warning('Some duplicate ids were found!')
                else
                    d = setdiff(subspace, id);
                    disp(d)
                    warning('%d ids were not found!, ignoring...', numel(d))
                end
                
            end
            assert(ignore_missing, 'exiting');
        end
    end
else
    % non-id field, dups can occur
    in_subspace = ismember(subspace, id);
    revspace = setdiff(universe, subspace);
    in_revspace = ismember(revspace, id);
    
    if (~exclude_flag && ~isequal(length(subspace), nnz(in_subspace))) || ...
            (exclude_flag && ~isequal(length(revspace), nnz(in_revspace)))
        has_missing = true;
        if (ignore_missing && isverbose) || ~ignore_missing
            if exclude_flag
                disp(setdiff(revspace, id))
            else
                disp(setdiff(subspace, id))
            end
            warning('Some ids were not found!')
            assert(ignore_missing, 'exiting');
        end
    end
end
end