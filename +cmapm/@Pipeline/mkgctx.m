function dsfile = mkgctx(dsfile, ds, varargin)
% MKGCTX Save an annotated matrix in GCTX format.
% MKGCTX(DSFILE, DS)
% MKGCTX(DSFILE, DS, 'param', value, ...) Specify optional parameters
%   Parameter       Value
%   'appenddim'     Append matrix dimensions to filename {[true], false}
%   'compression'   Specify data compression algorithm {['none'], 'gzip'}.
%                   Note that using compression will create small files but
%                   increase read times.
%   'compression_level' Compression level if compression is specified
%                   [0-9]. Default is 6
%   'overwrite'     Overwrite data {true, [false]}
%   'root'          Root group location in the GCTX file. Default is '0'
%   'dsname'        Data matrix location. Default is '0'
%

% Note: assumes data matrix is at single precision

dsfile = mkgctx(dsfile, ds, varargin{:});

end
