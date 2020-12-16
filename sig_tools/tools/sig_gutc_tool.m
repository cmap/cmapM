function sig_gutc_tool(varargin)
% sig_gutc_tool Compute percentile connectivity scores to of queries to CMap perturbagens
% See: sig_gutc_tool -h for details

obj = mortar.sigtools.SigGutc;
obj.run(varargin{:});

end