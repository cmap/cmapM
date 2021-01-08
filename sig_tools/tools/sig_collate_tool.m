function sig_collate_tool(varargin)
% SIG_COLLATE_TOOL Merge datasets
% See: sig_collate_tool -h for details

obj = mortar.sigtools.SigCollate;
obj.run(varargin{:});

end