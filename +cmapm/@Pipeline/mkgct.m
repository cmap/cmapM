function ofile = mkgct(ofile, gex, varargin)
% MKGCT.M Create a gct file.
%   MKGCT(OFILE, GEX) Creates OFILE in gct format. GEX is a structure with
%   the following fields:
%   Creates a v1.3 GCT file named OFILE. GEX is a structure with the 
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename
%
%   MKGCT(OFILE, GEX, 'param', value, ...) accepts one or more
%   comma-separated parameter name/value pairs. The following parameters
%   are recognized:
%
%   'precision': scalar, restricts number of digits after the decimal point
%               to N digits. Default: 4
%   'appenddim': boolean, append dimensions of the data matrix
%               to the filename. Default=true
%   'version': scalar, Support versions 2,3. Default=3. If v3 is selected
%               GEX must contain the SDESC field.
%
% See also PARSE_GCT

ofile = mkgct(ofile, gex, varargin{:});

end