function [tbl, keep_rec] = filter_record(tbl, filt_list, varargin)
% FILTER_RECORD Filter records from a structure array
%   [TBL_FILT, KEEP_REC] = FILTER_RECORD(TBL, FILT_LIST) TBL is a structure
%   array or TSV file. FILT_LIST is a set of filter rules as returned by
%   the PARSE_FILTER function. TBL_FILT is a structure array of records in
%   TBL that pass the filters specified in FILT_LIST. KEEP_REC is a logical
%   vector of length equal to the number of record in TBL indicating
%   records that were selected.
%
% See PARSE_FILTER for details on specifying filter rules.

config = struct('name', {'--detect_numeric'},...
    'default', {true},...
    'help', {'Detect and cast numeric fields if true'});
opt = struct('prog', mfilename, 'desc', 'Build widgets');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
if ~help_flag
    [tbl, isfieldnum] = parse_record(tbl, 'detect_numeric', args.detect_numeric);
    filt_list = parse_filter(filt_list);
    tbl_fields = fieldnames(tbl);
    tbl_field_lut = mortar.containers.Dict(tbl_fields);
    nrec = length(tbl);
    
    filt_fields = {filt_list.head}';
    id_field_idx = strcmp('_id', filt_fields);
    if nnz(id_field_idx)
        id_fields = {'rid'; 'cid'};
        [c, ~, ib] = intersect(tbl_fields, id_fields);
        if numel(c)>1
            error('Ambiguous mapping of _id to id field. Found both rid and cid in the table')
        else
            dbg(1, 'Mapping id_ field to %s', id_fields{ib});
            filt_fields(id_field_idx) = id_fields(ib);
            filt_list = setarrayfield(filt_list, id_field_idx, 'head', id_fields{ib});
        end                
    end
    
    has_all_fields = ismember(filt_fields, tbl_fields);
    nfilt = nnz(has_all_fields);
    ifilt = find(has_all_fields);
    itbl = tbl_field_lut(filt_fields(has_all_fields));
    
    if ~has_all_fields
        diff_fn = setdiff(filt_fields, tbl_fields);
        nmiss = length(diff_fn);
        if nmiss>0
            dbg(1, '%d of %d filter fields are missing from target table, ignoring them',...
                nmiss, length(filt_fields))
            disp(diff_fn);
        end
    end
    
    keep_rec = true(nrec, 1);
    dbg(1, 'Applying %d filters...', nfilt);
    for ii=1:nfilt
        this_filt = filt_list(ifilt(ii));
        this_field = this_filt.head;
        if isfieldnum(itbl(ii))
            val_is_num = true;
            this_val = [tbl.(this_field)]';
        else
            val_is_num = false;
            this_val = {tbl.(this_field)}';
        end
        this_match = do_match(this_val, val_is_num, this_filt);
        
        if this_filt.do_and_op
            keep_rec = keep_rec & this_match;
        else
            keep_rec = keep_rec | this_match;
        end
        
        dbg(1, '%d/%d Filter by %s (%s), %d/%d records match',...
            ii, nfilt, this_filt.head, this_filt.desc, nnz(this_match), nrec);
    end
    dbg(1, 'After all filters %d/%d records match',...
        nnz(keep_rec), nrec);
    tbl = tbl(keep_rec);
    
end
end
function assertIsCellString(field_id, is_num)
assert(~is_num, ...
    'Expected cell string for field %s got numeric instead',...
    field_id);
end

function assertIsNumeric(field_id, is_num)
assert(is_num, ...
    'Expected numeric array for field %s',...
    field_id);
end

function ismatch = do_match(tbl_val, val_is_num, filt)
filt_id = filt.head;
filt_type = filt.desc;
filt_rule = filt.entry;
nrec = length(tbl_val);
do_reverse_match = filt.do_reverse_match;

switch filt_type
    case 'regexpi'
        % case insensitive partial match
        assertIsCellString(filt_id, val_is_num);
        ismatch = true(nrec, 1);
        for ii=1:length(filt_rule)
            this_match = cellfun(@length,...
                regexpi(tbl_val, filt_rule{ii}))>0;
            ismatch = ismatch & this_match;
        end
        
    case 'regexp'
        % case sensitive partial match
        assertIsCellString(filt_id, val_is_num);
        ismatch = true(nrec, 1);
        for ii=1:length(filt_rule)
            this_match = cellfun(@length,...
                regexp(tbl_val, filt_rule{ii}))>0;
            ismatch = ismatch & this_match;
        end
        
    case 'exact'
        % exact string match
        assertIsCellString(filt_id, val_is_num);
        lut = mortar.containers.Dict(filt_rule);
        ismatch = lut.isKey(tbl_val);
        %ismatch = ismember(tbl_val, filt_rule);
        
    case 'range'
        % Numeric range
        assertIsNumeric(filt_id, val_is_num);
        min_val = filt_rule{1};
        max_val = filt_rule{2};
        ismatch = tbl_val >= min_val & tbl_val <= max_val;
        
    case 'topn'
        % Top N numeric values
        assertIsNumeric(filt_id, val_is_num);
        num_to_pick = filt_rule{1};
        ismatch = false(nrec, 1);
        [~, idx] = get_topn(tbl_val, num_to_pick, 1, 'descend', false);
        ismatch(idx) = true;
        
    case 'botn'
        % Bottom N numeric values
        assertIsNumeric(filt_id, val_is_num);
        num_to_pick = filt_rule{1};
        ismatch = false(nrec, 1);
        [~, idx] = get_topn(tbl_val, num_to_pick, 1, 'ascend', false);
        ismatch(idx) = true;
        
    case 'topbotn'
        % Top and Bottom N values
        assertIsNumeric(filt_id, val_is_num);
        num_to_pick = filt_rule{1};
        ismatch = false(nrec, 1);
        [~, idx] = get_topn(tbl_val, num_to_pick, 1, 'descend', true);
        ismatch(idx) = true;
        
    otherwise
        msgid = sprintf('%s:badFilterType', mfilename);
        error(msgid, 'Unknown filter type: %s', filt_type)
end

if do_reverse_match
    ismatch = ~ismatch;
end
end



