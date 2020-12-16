function sig_geneconvert_tool(varargin)
% sig_geneconvert_tool Convert gene identifiers to L1000 compatible ids
% See: sig_geneconvert_tool -h for details

obj = mortar.sigtools.SigGeneConvert;
obj.run(varargin{:});

end