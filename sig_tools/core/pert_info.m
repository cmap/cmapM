function [info, keys] = pert_info(q, varargin)
% PERT_INFO Get perturbagen annotations from Mongo.
%   INFO = PERT_INFO(PERT_ID) Returns annotations for each pert id.
%   SIG_ID can be a string, cell array or a GRP file. INFO is a structure
%   with length(PERT_ID) rows.
%
%   Example:
%   pert_info('BRD-A19037878')

[info, keys] = mongo_info('pert_info', q, varargin{:});

end