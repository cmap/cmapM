function [info, keys] = cell_info(q, varargin)
% CELL_INFO Get cell line annotations from Mongo.
%   INFO = CELL_INFO(CELL_ID) Returns annotations for each cell id.
%   CELL_ID can be a string, cell array or a GRP file. INFO is a structure
%   with length(CELL_ID) rows. CELL_ID can also be a valid JSON string.
%
%   Example:
%   cell_info('MCF7')

[info, keys] = mongo_info('cell_info', q, varargin{:});

end