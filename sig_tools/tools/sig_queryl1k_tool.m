function sig_queryl1k_tool(varargin)
% sig_queryl1k_tool Compute the geneset enrichment similarity between input genesets (aka queries) and an L1000 dataset
% See: sig_queryl1k_tool -h for details

obj = mortar.sigtools.SigQueryl1k;
obj.run(varargin{:});

end