function [gpvar, gp, gpidx, cmn_hd, gpsz] = get_groupvar(desc, hd, gpid, varargin)
% GET_GROUPVAR Create a grouping variable.
%   [GPVAR, GP, GPIDX, CMN_FN, GPSZ] = GET_GROUPVAR(C, FN, GP) where C is a
%   cell array of categorical, numeric or logical values, FN is cell array
%   of column names of C and GP is a cell array or comma separated string
%   listing the fieldnames to use for the grouping. GPVAR is the grouping
%   variable, GP is a unique list of groups and GPIDX is an index vector
%   taking values from 1 to length(GP) such that GP(GPIDX) = GPVAR. CMN_FN
%   is the list of column names used. GPSZ is the size of each group.
%
%   [GPVAR, GP, GPIDX, CMN_FN, GPSZ] = GET_GROUPVAR(S, [], GP) S is a
%   structure or structure array and GP is a cell array or comma separated
%   string of fieldnames of S
%   
%   GET_GROUPVAR(C, FN, GP, 'param1', value1, ...) Specify optional
%   parameters. Valid parameters are:
%
%   'dlm' : char, delimiter used for joining group components. 
%           Default is ':'
%   'add_unit' : boolean, Append units to grouping variable if true. The units are
%           assumed to be in a field named <GPID>_unit. Default is false
%   'skip_static' : boolean, If true, skip group field if its value does
%   not change. Default is false
%   'skip_undef' : boolean, if true, skip fields silently if its missing. Default is
%   false.
%   'skip_missing' : boolean, Default is false
%   'no_space' : boolean, if true strip whitespace. Default is false

% Example: 
% C = {'A', 10; 'B', 20; 'C', 20; 'A', 10} 
% [GPVAR, GP, GPIDX] = GET_GROUPVAR(C, {'id', 'value'}, {'value', 'id'})

pnames = {'add_unit', 'skip_static', 'skip_undef',...
          'dlm', 'skip_missing', 'no_space',...
          'case'};
dflts = {false, false, false,...
         ':', false, false,...
         ''};

args = parse_args(pnames, dflts, varargin{:});

if ischar(gpid)
    gpid = tokenize(gpid, ',', true);
end

if isstruct(desc)
    hd = fieldnames(desc);
end

[cmn_hd, gpidx] = intersect_ord(hd, gpid);
ngp = length(gpidx);
if ~isequal(length(gpid), ngp)
    if args.skip_missing
        gpid = cmn_hd;        
    else
        disp(setdiff(gpid, cmn_hd));
        error('Some fields not found');
    end
end

hdict = list2dict(hd);
gpvar = '';

keep_hd = true(ngp, 1);
isfirst = false;
for ii=1:ngp    
    addme = get_column(desc, hd{gpidx(ii)}, hdict);

    if args.skip_static
        keep_hd(ii) = ~isstatic(addme);
    end
    if args.skip_undef
        keep_hd(ii) = ~isundef(addme);
    end
    % if numeric and convert to string
    this_class = unique(cellfun(@class, addme, 'uniformoutput', false));
    if all(ismember(this_class, {'single', 'double', 'logical'}))
        addme = num2cellstr(cell2mat(addme));
    end
    if args.add_unit
        addme = add_unit(addme, gpid{ii}, desc, hdict);
    end
    switch (args.case)
      case 'upper'
        addme = upper(addme);
      case 'lower'
        addme = lower(addme);
    end
    if args.no_space
        addme = strrep(addme, ' ', '');
    end
    addme = strrep(addme, args.dlm, '');
    if isfirst && keep_hd(ii)
        gpvar = strcat(gpvar, args.dlm, addme);
    elseif keep_hd(ii)
        gpvar = addme;
        isfirst = true;
    end
end

[gp, gpidx] = getcls(gpvar);
cmn_hd = cmn_hd(keep_hd);
gpsz = accumarray(gpidx, ones(size(gpidx)));

end

function tf = isstatic(x)

if isnumeric_type(x)
    minval = min(length(cell2mat(x))-1, 1);
    tf = isequal(length(unique(cell2mat(x))), minval);
else
    minval = min(length(x)-1, 1);
    tf = isequal(length(unique(x)), minval);
end
end

function tf = isundef(x)

if isnumeric_type(x)    
    tf = all((cell2mat(x) + 666) < eps);
else    
    tf = all(strcmp('-666', x));
end
end

function col = get_column(desc, col_id, hdict)
switch(class(desc))
    case 'cell'
        col = desc(:, hdict(col_id));
    case 'struct'
    if length(desc) > 1
        col = {desc.(col_id)}';
    else
        if iscell(desc.(col_id))
            col = desc.(col_id);
        else
            col = {desc.(col_id)};
        end
    end        
end
end

function gpvar = add_unit(gpvar, gpid, desc, hdict)
% append units if available
unit_field = [gpid, '_unit']; 
if hdict.isKey(unit_field)
    unit = get_column(desc, unit_field, hdict);
%     unit = desc(:, hdict(unit_field));
    % ignore blank fields
    unit(strcmp('-666', unit))={''};
    gpvar = strcat(gpvar, unit);
end
end
