function sig_curie_tool(varargin)
% sig_curie_tool Execute queries on cell viability profiles
% See: sig_curie_tool -h for details

obj = mortar.sigtools.SigCurie;
obj.run(varargin{:});

end