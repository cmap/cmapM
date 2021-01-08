function sig_slice_tool(varargin)
% SIG_SLICE_TOOL Extract a subset of signatures
% See: sig_slice_tool -h for details

obj = mortar.sigtools.SigSlice;
obj.run(varargin{:});

end