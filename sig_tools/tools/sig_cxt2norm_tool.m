function sig_cxt2norm_tool(varargin)
% sig_cxt2norm_tool Convert raw gene expression data to L1K compatible normalized values
% See: sig_cxt2norm_tool -h for details

obj = mortar.sigtools.SigCxt2Norm;
obj.run(varargin{:});

end