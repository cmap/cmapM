function ds = parse_gct(fname,varargin)
% PARSE_GCT Read a Broad GCT file
%   DS = PARSE_GCT(FNAME)
%   Reads a v1.2 or v1.3 GCT file FNAME and returns a structure with the 
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdict: Dictionary of row annotation fieldnames to indices
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdict: Dictionary of column annotation fieldnames to indices
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename
%
%   DS = PARSE_GCT(FNAME, param, value,...) Specify optional parameters.
%   Valid parameters are:
%       'class': Sets the class of the data matrix. Valid classes include:
%                'double', 'single', 'int8', 'uint8', 'int16', 'uint16', 
%                'int32', 'uint32', 'int64', 'uint64' and 'logical'. 
%                See CLASS for descriptions.
%
%       'detect_numeric': Converts numeric annotation fields in rdesc and 
%                         cdesc to numbers
%

% Wrapper for private function
ds = parse_gct(fname, varargin{:});

end
