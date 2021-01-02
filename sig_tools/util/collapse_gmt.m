function gmt = collapse_gmt(gmt)
% COLLAPSE_GMT collapses cell array of cells or GMT sets 
%   into single cell array
% GMT = COLLAPSE_GMT(GMT)

if isfileexist(gmt,'file')
    gmt = parse_gmt(gmt);
end

if isstruct(gmt)
    assert(isfield(gmt,'entry'), 'Invalid structure');
    gmt = {gmt.entry};
end

ind = cellfun(@isrow,gmt);

%entries should be row vectors
if ~all(ind)
    rt = cellfun(@transpose,gmt(~ind),'UniformOutput',false);
    gmt(~ind) = rt;
end

gmt = [gmt{:}];