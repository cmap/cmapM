function id = append_id(sid,T)
% APPEND_ID    Appends a cluster indicator to sid
%   id = append_id(sid,T) will append a cluster membership id to
%   each sample id. The cluster membership id is the output from
%   any clustering method. The vectors sid and T are element
%   consistent.  
%   Inputs:  
%      T - A vector which indicates the cluster membership of each
%      sample, 1 by n
%      sid - a cell array which specifies the sample label, 1 by n
%   Outputs: 
%      id - a cell array with sid and membership indicator
%
%   Note: This is a subroutine called by consensus clustering code
%   See also conclust, conCluster
% 
% Author: Brian Geier, Broad 2010   

id = cell(length(sid),1); 
[~,ix] = sort(T); 
if length(sid) <= 250
    for i = 1 : length(sid)
        id{i} = horzcat(num2str(T(ix(i))),'-',sid{ix(i)}); 
    end
else
    for i = 1 : length(sid)
        id{i} = num2str(T(ix(i))); 
    end
end
