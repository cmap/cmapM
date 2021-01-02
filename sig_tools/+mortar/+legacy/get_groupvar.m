function [gpvar, gp, gpidx] = get_groupvar(desc, hd, gpid, varargin)
% Create a grouping variable.
%   [GPVAR, GP, GPIDX] = GET_GROUPVAR(C, FN, GP) where C is a cell array of
%   categorical, numeric or logical values, FN is cell array of column
%   names of C and GP is a cell array or comma separated string listing the
%   fieldnames to use for the grouping. GPVAR is the grouping variable, GP
%   is a unique list of groups and GPIDX is an index vector taking values
%   from 1 to length(GP) such that GP(GPIDX) = GPVAR
%
% Example: C = {'A', 10; 'B', 20; 'C', 20; 'A', 10} [GPVAR, GP, GPIDX] =
% get_groupvar(C, {'id', 'value'}, {'value', 'id'})

pnames = {'add_unit'};
dflts = {true};
args = parse_args(pnames, dflts, varargin{:});

if ischar(gpid)
    gpid = tokenize(gpid, ',');
end

[~, gpidx] = intersect_ord(hd, gpid);
ngp = length(gpidx);
hdict = list2dict(hd);
gpvar = '';

for ii=1:ngp
    addme = desc(:, gpidx(ii));
    %if numeric and convert to string
    this_class = unique(cellfun(@class, addme, 'uniformoutput', false));
    if all(ismember(this_class, {'single', 'double', 'logical'}))
        addme = num2cellstr(cell2mat(addme));
    end
    if args.add_unit
        addme = add_unit(addme, gpid{ii}, desc, hdict);
    end
    addme = strrep(addme, ':', '');
    if ii>1
        gpvar = strcat(gpvar, ':', addme);
    else
        gpvar = addme;
    end
end

[gp, gpidx] = getcls(gpvar);
    
end

function gpvar = add_unit(gpvar, gpid, desc, hdict)
% append units if available
unit_field = [gpid, '_unit']; 
if hdict.isKey(unit_field)
    unit = desc(:, hdict(unit_field));
    % ignore blank fields
    unit(strcmp('-666', unit))={''};
    gpvar = strcat(gpvar, unit);
end
end