classdef Validate
    % Class for validating various CMap inputs
    
    methods(Static=true)
        lxb_rpt = validateLXB(varargin)
        map_rpt = validateMapSource(varargin)
        filelist = validateIds(varargin)
        all_maps = assignReplicateGroups(all_maps, split_by, group_by, group_field);
    end
    
end