function format_mapfile(mapfile)
% FORMAT_MAPFILE
% Auto insert detection plate and well info to map file.
% Map file values will override the auto insert if det_well and det_plate
% fields are already specified in the file.
% Also filters out wells for which pert_id is CMAP-666

% read in the map
[~, f] = fileparts(mapfile);
plate_info = parse_platename(f, 'verify', false);
unimap_file = fullfile(cmapmpath, 'resources', 'uni_det_wells.txt');
map = parse_tbl(mapfile, 'detect_numeric', false, 'outfmt', 'record');
changed = false;

% add det_plate and det_well if they're not present
if ~all(isfield(map, {'det_plate', 'det_well'}))
    changed = true;
    nr = length(map);
    % add the det plate
    det_plate = repmat({f}, nr, 1);
    [map.det_plate] = det_plate{:};
    % add the det_well
    switch lower(plate_info.detmode)
        case 'duo'
            [map.det_well] = map.rna_well;
        case 'uni'            
            unimap = parse_tbl(unimap_file, 'outfmt', 'record');
            tbl = filter_table(unimap, {'side'}, {f(end)});
            [~, widx] = intersect_ord({tbl.rna_well}, {map.rna_well});
            [map.det_well] = tbl(widx).det_well;             
        otherwise
            error('unknown mode %s', det_mode)
    end
end

% filter out wells where pert_id is CMAP-666
isblank = strcmpi({map.pert_id}, 'CMAP-666');
if any(isblank)
    changed = true;
    map = map(~isblank);
end

% if either change was made, write the map file
if changed
    mktbl(mapfile, map)
end
