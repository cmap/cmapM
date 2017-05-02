classdef String
    
    methods (Static=true)
        % VALIDATEVAR check for valid matlab variable name.
        vn = validateVar(n, rep);
        
        % GEN_LABEL Generate labels
        lbl = genLabels(varargin);
        
        % TOKENIZE split a string based on a specified delimiter
        [tok,ntok] = tokenize(s,t,trim);
        
        % PrintDelimitedLine Print a delimited line
        varargout = printDelimitedLine(li, varargin);
        
        % STRINGIFY Convert input to string.
        s = stringify(x, varargin);

        % NUM2CELLSTR Convert an array of numbers into a cell array of
        % strings
        c = num2cellstr(x, varargin);

    end
end