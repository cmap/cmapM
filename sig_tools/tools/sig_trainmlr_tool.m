function sig_trainmlr_tool(varargin)
% sig_trainmlr_tool "Create a model given a dataset using multilinear regression."
% See: sig_trainmlr_tool -h for details

obj = mortar.sigtools.SigTrainMLR;
obj.run(varargin{:});

end