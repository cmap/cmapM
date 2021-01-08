classdef String
    
    methods (Static=true)
	% VALIDATEVAR check for valid matlab variable name.
	vn = validateVar(n, rep);

	% GEN_LABEL Generate labels
	lbl = genLabels(varargin);

    end
end