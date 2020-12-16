function filter_list = parse_filter(filter_list)
% PARSE_FILTER Read a filter list file
%   F = PARSE_FILTER(FL) FL is a GMT, GMX or GRP file or structure that
%   specifies one filter rule per entry (a GMT line or a GMX column).
%   Returns a data structure F that can be used with the FILTER_RECORD
%   function to select specific records from a structure array. If FL is a 
%   GRP file, the filter rule is to exactly match the _id field
%
%   Each rule comprises a target field, filter type and filter
%   pattern. The header entry specifies the target field to operate on, the
%   description entry specifies the filter type and the remaining entries
%   specify the filter pattern(s). Valid filter types include:
%
%   exact : Exact string match
%   regexp : Case-sensitive regular expression match
%   regexpi : Case-insensitive regular expression match
%   range : Match a numeric range, the first and second entries specify the
%           lower and upper bound of the range
%   topn : Top N records after sorting records on the target field in
%          descending order
%   botn : Bottom N records after sorting records on the target field in
%          descending order
%   topbotn : Top and Bottom N records after sorting records on the target field in
%          descending order
%
% To invert a filter rule prepend a ! before the filter type. E.g. !exact
% will return records that dont match the current rule.
%
% If multiple rules are specified, the default behavior is to return
% records that match all the rules i.e. perform an AND operation. To
% specify an OR operation prepend a | before the filter type.
%
% See FILTER_RECORD

if isfileexist(filter_list)
    [~, ~, e] = fileparts(filter_list);
    switch lower(e)
        case {'.gmt', '.gmx'}
            filter_list = parse_geneset(filter_list);
        case {'.grp'}
            % if GRP filter by exact match to _id field
            flist = parse_grp(filter_list);
            filter_list = mkgmtstruct({flist}, {'_id'}, {'exact'});            
        otherwise
            msgid = sprintf('%s:badFileFormat', mfilename);
            error(msgid, 'Invalid file format, expected GMT or GMX got %s', e);
    end
elseif isstruct(filter_list)
    % use struct as-is
else
    error('File not found: %s', filter_list);
end

% String filters
str_filt_type = {'exact'; 'regexp'; 'regexpi'};
% Numeric filters
num_filt_type = {'range'; 'topn'; 'botn'; 'topbotn'};
valid_filt_type = [str_filt_type; num_filt_type];

nfilt = length(filter_list);
filt_type = {filter_list.desc}';

if isfield(filter_list, 'do_and_op')
    do_and_op = [filter_list.do_and_op]';
else
    do_and_op = true(nfilt, 1);
    is_or_op = strncmp(filt_type, '|', 1);
    do_and_op(is_or_op) = false;
end

filt_type = strrep(filt_type, '|', '');
if isfield(filter_list, 'do_reverse_match')
    do_reverse_match = [filter_list.do_reverse_match]';
else
    do_reverse_match = false(nfilt, 1);
    is_rev_match = strncmp(filt_type, '!', 1);
    do_reverse_match(is_rev_match) = true;
    filt_type = strrep(filt_type, '!', '');
end

is_valid_filt_type = ismember(filt_type, valid_filt_type);
if ~all(is_valid_filt_type)
    invalid_types = {filter_list(~is_valid_filt_type).desc}';
    num_invalid = length(invalid_types);
    dbg(1, '%d Invalid filter type specified', num_invalid)
    disp(invalid_types)
    msgid = sprintf('%s:badFilterTypes', mfilename);
    error(msgid, 'Invalid types specified');
end

is_num_filt = ismember(filt_type, num_filt_type);
num_filt_idx = find(is_num_filt);
num_numeric_filt = length(num_filt_idx);
for ii=1:num_numeric_filt
    val = filter_list(num_filt_idx(ii)).entry;
    is_num = mortar.util.DataType.isCellNumeric(val);
    if ~all(is_num)
        val = str2double(val);
        is_not_nan = all(~isnan(val));
        if ~is_not_nan
            dbg(1, 'No numeric values specified for Numeric filter: %s',...
                filter_list(num_filt_idx(ii)).head);
            msgid = sprintf('%s:badFilterValue', mfilename);
            error(msgid, 'Invalid numeric value specified');
        end
        filter_list(num_filt_idx(ii)).entry = num2cell(val);
    end
end

filter_list = setarrayfield(filter_list, [],...
    {'desc', 'do_and_op', 'do_reverse_match'},...
    filt_type, do_and_op, do_reverse_match);
end