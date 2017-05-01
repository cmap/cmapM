function ds = parse_gctx(dsfile, varargin)
%   DS = PARSE_GCTX(DSFILE) Reads a GCTX file and returns a structure
%   with the following fields:
%
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
%       src: Path of source filename
%       h5path: Path of data matrix in the GCTX file
%       h5name: Dataset name
%
%   The default is to return the dataset stored at '/0/DATA/0/matrix'
%   within the GCTX file. To specify an alternate location specify the
%   'root' and 'dsname' options.
%
%   DS = PARSE_GCTX(DSFILE, 'param1', value1, ...) Specify optional
%   parameters:
%
%   'rid': <Cell array> specifying a subset of row identifiers to extract.
%           Default is to return all rows.
%
%   'cid': <Cell array> specifying a subset of column identifiers to
%           extract. Default is to return all columns.
%
%   'annot_only': <Boolean> Extract only row and column meta-data without
%           the data matrix. Default is false.
%
%   'detect_numeric': <Boolean> Identifies numeric meta-data and casts
%           them to a an appropriate data type. Default is true
%
%   'root': Root group location in the GCTX file. Default is '0'
%
%   'dsname': Data matrix location. Default is '0'
%
%   'annot_precision': Numeric precision of numeric meta-data. Only applies
%           if detect_numeric is false. Default is 2.

ds = parse_gctx(dsfile, varargin{:});

end
