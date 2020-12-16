function sig_build_tool(varargin)
% sig_build_tool  Generate L1k signature build from a list of brews
% See: sig_build_tool -h for details

obj = mortar.sigtools.SigBuild;
obj.run(varargin{:});

end