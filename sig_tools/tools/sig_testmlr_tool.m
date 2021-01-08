function sig_testmlr_tool(varargin)
% sig_testmlr_tool "Apply given model to predict genes using multiple linear regression."
% See: sig_testmlr_tool -h for details

obj = mortar.sigtools.SigTestMLR;
obj.run(varargin{:});

end