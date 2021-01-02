function sig_score2rank_tool(varargin)
% sig_score2rank_tool Generate rank matrix from score matrix
% See: sig_score2rank_tool -h for details

obj = mortar.sigtools.SigScore2Rank;
obj.run(varargin{:});

end