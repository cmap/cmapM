function sig_tsne_tool(varargin)
% SIG_TSNE_TOOL Run t-SNE on a multi-dimensional data matrix.
% See: sig_tsne_tool -h for details

obj = mortar.sigtools.SigTSNE;
obj.run(varargin{:});

end