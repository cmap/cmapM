function [table_type, nrec] = getTableType(tbl)
% getTableType Check type of table structure.
% T = getTableType(TBL) Checks if struct TBL is a structure array if the
% fields are cell arrays. T is either 'struct_array' or 'struct_cell'
%
% [T, L] = getTableType(TBL)

assert(isstruct(tbl), 'Expected struct as input got %s instead', class(tbl));
nrec = length(tbl);
table_type = 'struct_array';
if isequal(nrec, 1)
    fn = fieldnames(tbl);
    [is_same_len, len] = check_field_length(tbl, fn);
    if is_same_len && len>0
        table_type = 'struct_cell';
        nrec = len;
    end
end

end

function [same_len, len] = check_field_length(tbl, fn)
nf = length(fn);
first_field = tbl.(fn{1});
if iscell(first_field)
    len = length(tbl.(fn{1}));
    same_len = true;
    for ii=2:nf
        if ~isequal(len, length(tbl.(fn{ii})))
            same_len = false;
            break;
        end
    end
else
    % singleton struct, treat as array
    len = 1;
    same_len = false;
end
end