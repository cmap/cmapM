function sig_recall_tool(varargin)
% sig_recall_tool Compare replicates signatures to assess similarity
% See: sig_recall_tool -h for details

obj = mortar.sigtools.SigRecall;
obj.run(varargin{:});

end