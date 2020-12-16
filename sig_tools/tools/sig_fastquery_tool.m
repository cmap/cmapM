function sig_fastquery_tool(varargin)
% sig_fastquery_tool Compute weighted connectivity score using faster C++ implementation
% See: sig_fastquery_tool -h for details

obj = mortar.sigtools.SigFastQuery;
obj.run(varargin{:});

end