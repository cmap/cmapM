function sig_gseapreranked_tool(varargin)
% sig_gseapreranked_tool Run GSEA on rank-ordered lists
% See: sig_gseapreranked_tool -h for details

obj = mortar.sigtools.SigGseaPreranked;
obj.run(varargin{:});

end