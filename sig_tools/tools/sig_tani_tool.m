function sig_tani_tool(varargin)
% sig_tani_tool Calculate Tanimoto coefficients for a given set of compounds.
% See: sig_tani_tool -h for details

obj = mortar.sigtools.SigTani;
obj.run(varargin{:});

end