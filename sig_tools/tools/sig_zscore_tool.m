function sig_zscore_tool(varargin)
% sig_zscore_tool "Testing Toolify with SigZscore"
% See: sig_zscore_tool -h for details

obj = mortar.sigtools.SigZScore;
obj.run(varargin{:});

end