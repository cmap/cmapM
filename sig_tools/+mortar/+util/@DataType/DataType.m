classdef DataType
    
    properties (Constant)
        NUMERIC_TYPES = {'double', 'single', 'int8', ...
            'uint8', 'int16', 'uint16',...
            'int32', 'uint32', 'int64', ...
            'uint64', 'logical'};
    end
    methods (Static=true)
        
        % Check if input matches a numeric type.
        tf = isNumericType(t);
        
        % detect numeric fields and convert them
        [desc, numeric] = detectNumeric(desc);
        
        % Convert cell with headers to a structure.
        s = table2struct(tbl, hdr);
        
        % IsCellNumeric True for cell array of numeric values.
        tf = isCellNumeric(s)
        
        % Check type of table structure.
        [t, l] = getTableType(tbl);
        
        % Detect and optionally convert numeric fields in a table struct
        [isnum, tbl] = detectTableNumericFields(tbl, do_convert_field);

    end
end
