function combods = merge_two(ds1, ds2, varargin)
%function combods = merge_two(ds1, ds2, varargin)
% MERGE_TWO Combine two datasets
% parameters:
%   verbose:  true/false
%   merge-direction:  auto-determine(default), along-columns, along-rows

config = struct('name', {'--verbose', '--merge_direction', '--merge_partial', '--missing_value'}, ...
    'default', {false, 'auto-determine', false, nan}, ...
    'choices', {{true, false}, {'auto-determine', 'along-columns', 'along-rows'}, {true, false}, {}}, ...
    'help', {'whether to print a bunch of output',...
    'direction along which the datasets should be merged',...
    'Adjust dataset for missing ids',...
    'missing value if pad_missing is true'});
opt = struct('prog', 'merge_two', 'desc', 'merge two datasets');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


combods = mkgctstruct();
%cmncid = intersect_ord(ds2.cid, ds1.cid);
%cmnrid = intersect_ord(ds2.rid, ds1.rid);

cid1_lut = mortar.containers.Dict(ds1.cid);
%cid2_lut = mortar.containers.Dict(ds2.cid);
rid1_lut = mortar.containers.Dict(ds1.rid);
%rid2_lut = mortar.containers.Dict(ds2.rid);

cmncid = ds1.cid(cid1_lut.isKey(ds2.cid));
cmnrid = ds1.rid(rid1_lut.isKey(ds2.rid));

[nr1, nc1] = size(ds1.mat);
[nr2, nc2] = size(ds2.mat);
nc = length(cmncid);
nr = length(cmnrid);

to_pad_missing = false;
switch args.merge_direction
    case 'auto-determine'
        % unique column ids with overlapping row ids
        if isempty(cmncid) && ~isempty(cmnrid)
            if ~isequal(nr, nr1)
                assert(args.merge_partial,...
                    'PARTIAL_OVERLAP: Only %d of %d row ids are common. Specify merge_partial 1 to merge', nr, nr1)
                to_pad_missing = true;
            end
            my_merge_direction = 'along-columns';
        elseif isempty(cmnrid) && ~isempty(cmncid)
            if ~isequal(nc, nc1)
                assert(args.merge_partial,...
                    'PARTIAL_OVERLAP: Only %d of %d column ids are common. Specify merge_partial 1 to merge', nc, nc1)
                to_pad_missing = true;
            end
            my_merge_direction = 'along-rows';
        else
            error('merge_two:cannotDetermineMergeDirection',...
                ['when using merge_direction auto-determine, ',...
                'either row or column-ids must match across datasets, ',...
                'and the other dimension must have no overlaps, ',...
                'but for the provided they do not']);
        end
        
    case 'along-columns'
        % column ids must be unique
        if ~isempty(cmncid)
            error('merge_two:cannotMergeAlongColumns',...
                'could not merge along columns because the datasets have some identical column ids');
        elseif ~isequal(nr, nr1)
            assert(args.merge_partial,...
                'PARTIAL_OVERLAP: Only %d of %d row ids are common. Specify merge_partial 1 to merge', nr, nr1)
            to_pad_missing = true;
        end
        my_merge_direction = 'along-columns';
        
    case 'along-rows'
        if ~isempty(cmnrid)
            error('merge_two:cannotMergeAlongRows',...
                'could not merge along rows because the datasets have some identical row ids');
        elseif ~isequal(nc, nc1)
            assert(args.merge_partial,...
                'PARTIAL_OVERLAP: Only %d of %d column ids are common. Specify pad_missing 1 to merge', nc, nc1);
            to_pad_missing = true;
        end
        
        my_merge_direction = 'along-rows';
end

switch my_merge_direction
    case 'along-columns'
        dbg(args.verbose, 'Appending cols')
        
        if to_pad_missing
            dbg(args.verbose, 'Partial overlaps of row ids, filling missing values with %g', args.missing_value)
            cmnrid = union(ds1.rid, ds2.rid, 'stable');
            ds1 = ds_pad(ds1, cmnrid, '', args.missing_value);
            ds2 = ds_pad(ds2, cmnrid, '', args.missing_value);
        end
        
        combods.cid = [ds1.cid; ds2.cid];
        
        combods.rid = cmnrid;
        
        % row annotation
        combods.rhd = ds1.rhd;
        combods.rdesc = ds1.rdesc;
        
        % data matrix
        [~, ridx1] = intersect_ord(ds1.rid, combods.rid);
        [~, ridx2] = intersect_ord(ds2.rid, combods.rid);
        combods.mat = [ds1.mat(ridx1,:), ds2.mat(ridx2,:)];
        
        % column annotation
        combods.chd = union(ds1.chd, ds2.chd);
        if ~isempty(combods.chd)
            [~, chdx1, cmnchdx1] = intersect_ord(ds1.chd, combods.chd);
            [~, chdx2, cmnchdx2] = intersect_ord(ds2.chd, combods.chd);
            combods.cdesc = cell(nc1+nc2, length(combods.chd));
            combods.cdesc(:) = {-666};
            if ~isempty(chdx1)
                combods.cdesc(1:nc1, cmnchdx1) = ds1.cdesc(:, chdx1);
            end
            if ~isempty(chdx2)
                combods.cdesc(nc1+(1:nc2), cmnchdx2) = ds2.cdesc(:, chdx2);
            end
            % fix multi-class columns
            combods.cdesc = fix_annotation_class(combods.cdesc);
        end
        
    case 'along-rows'
        % rids are disjoint and cids intersect : append rows
        dbg(args.verbose, 'Appending rows')
        if to_pad_missing
            dbg(args.verbose, 'Partial overlaps of column ids, filling missing values with %g', args.missing_value)
            cmncid = union(ds1.cid, ds2.cid, 'stable');
            ds1 = ds_pad(ds1, '', cmncid, args.missing_value);
            ds2 = ds_pad(ds2, '', cmncid, args.missing_value);
        end
        combods.rid = [ds1.rid; ds2.rid];
        combods.cid = cmncid;
        %column annotation
        combods.chd = ds1.chd;
        combods.cdesc = ds1.cdesc;
        
        %data matrix
        [~, cidx1] = intersect_ord(ds1.cid, combods.cid);
        [~, cidx2] = intersect_ord(ds2.cid, combods.cid);
        combods.mat = [ds1.mat(:, cidx1); ds2.mat(:, cidx2)];
        
        %row annotation
        combods.rhd = union(ds1.rhd, ds2.rhd);
        if ~isempty(combods.rhd)
            [~, rhdx1, cmnrhdx1] = intersect_ord(ds1.rhd, combods.rhd);
            [~, rhdx2, cmnrhdx2] = intersect_ord(ds2.rhd, combods.rhd);
            combods.rdesc = cell(nr1+nr2, length(combods.rhd));
            combods.rdesc(:) = {-666};
            if ~isempty(rhdx1)
                combods.rdesc(1:nr1, cmnrhdx1) = ds1.rdesc(:, rhdx1);
            end
            if ~isempty(rhdx2)
                combods.rdesc(nr1+(1:nr2), cmnrhdx2) = ds2.rdesc(:, rhdx2);
            end
            % fix multi-class columns
            combods.rdesc = fix_annotation_class(combods.rdesc);
        end
end
% update dict
combods.cdict = list2dict(combods.chd);
combods.rdict = list2dict(combods.rhd);
end
