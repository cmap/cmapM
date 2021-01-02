function [info, keys] = sig_info(q, varargin)
% SIG_INFO Get signature annotations from Mongo.
%   INFO = SIG_INFO(SIG_ID) Returns annotations for each signature id.
%   SIG_ID can be a string, cell array or a GRP file. INFO is a structure
%   with length(SIG_ID) rows.
%
%   INFO = SIG_INFO(Q) Returns result of a mongo query. Q is JSON query
%   string.
%   Examples:
%   sig_info('ASG001_MCF7_6H:BRD-A19037878-001-04-9:10')
%   sig_info('{"pert_iname":"simvastatin"}')
 [info, keys] = mongo_info('sig_info', q, varargin{:});

end
