classdef DataType
    
    methods (Static=true)
        
        % Check if input matches a numeric type.
        tf = isNumericType(t);

        % detect numeric fields and convert them
        [desc, numeric] = detectNumeric(desc);
	
	% convert a table to a structure (this is in-house function
	% and in conflict with Matlab native function); this function
	% is used by merge_maps in espresso/roast
	s = table2struct(tbl, hdr);
    end
end
