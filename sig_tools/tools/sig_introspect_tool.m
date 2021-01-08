function sig_introspect_tool(varargin)
% sig_introspect_tool Compute internal connectivities between signatures
% See: sig_introspect_tool -h for details

obj = mortar.sigtools.SigIntrospect;
obj.run(varargin{:});

end