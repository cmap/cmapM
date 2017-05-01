function res = parse_lxb(lxbfile, varargin)
% PARSE_LXB Parse a Luminex LXB (binary or text) file
%   LXB = PARSE_LXB(LXBFILE) Returns a sructure (LXB) with data from all 
%   detected beads in a single LXB file with the following fields:
%   'RID', The identity of each bead [1-500], unassigned beads have RID=0
%   'RP1', corresponding fluorescent intensities of each bead
% 

% wrapper from private method
res = parse_lxb(lxbfile, varargin{:});

end
