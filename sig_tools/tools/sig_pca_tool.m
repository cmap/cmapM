function sig_pca_tool(varargin)
% SIG_PCA_TOOL Compute PCA on raw data
% See: sig_pca_tool -h for details

obj = mortar.sigtools.SigPCA;
obj.run(varargin{:});

end 