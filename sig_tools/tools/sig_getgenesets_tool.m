function sig_getgenesets_tool(varargin)
% sig_getgenesets_tool Extract top and botton N genes from dataset
% See: sig_getgenesets_tool -h for details

obj = mortar.sigtools.SigGetGenesets;
obj.run(varargin{:});

end