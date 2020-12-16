function sig_marker_tool(varargin)
% SIG_MARKER_TOOL Generate differential expression signatures.
% See: sig_marker_tool -h for details
obj = mortar.sigtools.SigMarker;
obj.run(varargin{:});
end