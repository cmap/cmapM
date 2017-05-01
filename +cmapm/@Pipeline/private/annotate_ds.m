function ds = annotate_ds(ds, annot, varargin)
% ANNOTATE_DS Annotate rows or columns in a dataset.
%   NEWDS = annotate_ds(DS, ANNOT) Updates column annotations
%   in DS using the annotations table ANNOT.
%
%   NEWDS = annotate_ds(DS, ANNOT, PARAM1, VAL1, ...) Specify optional
%   parameters:
%   'append' Appends to existing annotations if true. [{true}, false]
%   'dim'   Dimension to append to ['row', {'column'}]
%   'keyfield'  ANNOT field used to match to row or column of DS. Must be unique.
%               Default is 'id'
%   'skipmissing' Skip missing ids if true.  [true, {false}]
%   'missingval'    Value for missing ids if skipmissing is true.
%                   Default is '-666'

pnames = {'append', 'dim', 'keyfield',...
    'skipmissing', 'missingval', 'keepkey'};
dflts = {true, 'column', '',...
    false, '-666', false};
arg = parse_args(pnames, dflts, varargin{:});
arg.keyfield = lower(arg.keyfield);

if ~isstruct(annot)
    annot = parse_tbl(annot, 'outfmt','record', 'lowerhdr', true, 'detect_numeric', false);
end

if isempty(arg.keyfield)
    fn = fieldnames(annot);
    arg.keyfield = fn{1};
end

if ~isfield(annot, arg.keyfield)
    error('Keyfield (%s) not found in annot', arg.keyfield)
end

dups = duplicates({annot.(arg.keyfield)});
assert(isempty(dups), 'Duplicate entries found for keyfield: %s', arg.keyfield);

is_record = length(annot)>1 ||...
    (isequal(length(annot), 1) &&...
    ~iscell(annot.(arg.keyfield)));
if arg.keepkey
    annot_hdr = fieldnames(annot);
else
    annot_hdr = setdiff(fieldnames(annot), arg.keyfield, 'stable');
end
if ~isempty(annot_hdr)
    %annot_dict = mortar.containers.Dict(annot_hdr);
    annot_dict = list2dict(annot_hdr);
    nannot = length(annot_hdr);
    
    if ~isstruct(ds)
        ds = parse_gctx(ds);
    end
    [nr, nc] = size(ds.mat);
    
    switch lower(arg.dim)
        case 'column'
            if is_record
                [cmn, idx, idx2] = intersect_ord({annot.(arg.keyfield)}, ds.cid);
            else
                [cmn, idx, idx2] = intersect_ord(annot.(arg.keyfield), ds.cid);
            end
            if arg.append
                [keephd, keepidx] = setdiff(ds.chd, annot_hdr, 'stable');
                nkeep = length(keephd);
                ds.chd = [annot_hdr(:); keephd(:)];
                newdesc = cell(nc, nannot + nkeep);
                if nkeep>0
                    newdesc(:, (1:nkeep)+nannot) = ds.cdesc(:, keepidx);
                end
            else
                ds.chd = annot_hdr;
                newdesc = cell(nc, nannot);
            end
            if ~isequal(length(cmn), nc)
                if arg.skipmissing
                    [miss, midx] = setdiff(ds.cid, cmn, 'stable');
                    newdesc(midx, :) = {arg.missingval};
                else
		    dbg(10, 'there was a mismatch between the sig ids found in the data and those in the annotation.  Here is the set difference between the sig ids:')
                    disp(setdiff(ds.cid, cmn, 'stable'))
                    error('Annotations not found for some columns - see previous for difference between the sets of sig ids')
                end
            end
            for ii=1:nannot
                if is_record
                    newdesc(idx2, ii) = {annot(idx).(annot_hdr{ii})};
                else
                    newdesc(idx2, ii) = annot.(annot_hdr{ii})(idx);
                end
            end
            ds.cdesc = newdesc;
            if isfield(ds, 'cdict')
                ds.cdict = list2dict(ds.chd);
            end
        case 'row'
            if is_record
                [cmn, idx, idx2] = intersect_ord({annot.(arg.keyfield)}, ds.rid);
            else
                [cmn, idx, idx2] = intersect_ord(annot.(arg.keyfield), ds.rid);
            end
            if arg.append
                % keep fields not in the new annotation table
                [keephd, keepidx] = setdiff(ds.rhd, annot_hdr, 'stable');
                
                % keep data from shared fields
                [cmnhd, cmnidx] = intersect(ds.rhd, annot_hdr, 'stable');
                ncmn = length(cmnhd);
                
                nkeep = length(keephd);
                ds.rhd = [annot_hdr(:); keephd(:)];
                newdesc = cell(nr, nannot + nkeep);
                if nkeep>0
                    newdesc(:, (1:nkeep)+nannot) = ds.rdesc(:, keepidx);
                end
                if ncmn>0
                    newdesc(:, annot_dict(cmnhd)) = ds.rdesc(:, cmnidx);
                end
            else
                ds.rhd = annot_hdr;
                newdesc = cell(nr, nannot);
            end
            
            if ~isequal(length(cmn), nr)
                if arg.skipmissing
                    [miss, midx] = setdiff(ds.rid, cmn, 'stable');
                    ds.rdesc(midx, :) = {arg.missingval};
                else
                    disp(setdiff(ds.rid, cmn, 'stable'))
                    error('Annotations not found for some rows')
                end
            end
            
            for ii=1:nannot
                if is_record
                    newdesc(idx2, ii) = {annot(idx).(annot_hdr{ii})};
                else
                    newdesc(idx2, ii) = annot.(annot_hdr{ii})(idx);
                end
            end
            ds.rdesc = newdesc;
            if isfield(ds, 'rdict')
                ds.rdict = list2dict(ds.rhd);
            end
        otherwise
            error('Unknown dimension specified: %s. Should be ''column'' or ''row''');
    end
end

end
