function [isnum, tbl] = detectTableNumericFields(tbl, do_convert_field)
% detectTableNumericFields Detect and optionally convert numeric fields in
% a table structure
%   [ISNUM, T] = detectTableNumericFields(TBL, DO_CONVERT_FIELD)
%
fn = fieldnames(tbl);
nfield = length(fn);
[table_type, nrec] = mortar.util.DataType.getTableType(tbl);
isnum = false(nfield, 1);
for ii=1:nfield
    switch(table_type)
        case 'struct_array'
            desc = {tbl.(fn{ii})}';
            isnum(ii) = mortar.util.DataType.isCellNumeric(desc);
            if ~isnum(ii) && do_convert_field
                [val, isnum(ii)] = mortar.util.DataType.detectNumeric(desc);
                [tbl.(fn{ii})] = val{:};
            end
        case 'struct_cell'
            desc = tbl.(fn{ii});
            isnum(ii) = mortar.util.DataType.isCellNumeric(desc);            
            if ~isnum(ii) && do_convert_field
                [val, isnum(ii)] = mortar.util.DataType.detectNumeric(desc);
                tbl.(fn{ii}) = val;
            end
    end
end
end