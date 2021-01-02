function [info, keys] = inst_info(q, varargin)
% INST_INFO Get instance annotations from Mongo.
%   INFO = INST_INFO(INST_ID) Returns annotations for each instance id.
%   INST_ID can be a string, cell array or a GRP file. INFO is a structure
%   with length(INST_ID) rows.
%
%   INFO = INST_INFO(Q) Returns result of a mongo query. Q is JSON query
%   string.
%   Examples:
%   inst_info('KDA005_MCF7_96H_X1_B1_DUO45HI44LO:D1')
%   inst_info('{"pert_desc":"sirolimus"}')
 [info, keys] = mongo_info('inst_info', q, varargin{:});

end
