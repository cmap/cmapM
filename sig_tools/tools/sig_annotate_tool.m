function sig_annotate_tool(varargin)
% SIG_ANNOTATE_TOOL Extract annotations of a dataset
% See: sig_annotate_tool -h for details

obj = mortar.sigtools.SigAnnotate;
obj.run(varargin{:});

end