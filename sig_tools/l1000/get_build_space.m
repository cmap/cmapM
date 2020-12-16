function [space_file, annot, nel] = get_build_space(dim, build_id, space)
% GET_BUILD_SPACE Get row or column space for a given build.
% GET_BUILD_SPACE(DIM, BUILD_ID, SPACE) returns a file path to a list of
% identifiers that define a space.
% [SPC, ANNOT, NEL] = GET_BUILD_SPACE(DIM, BUILD_ID, SPACE) also returns a
% file with annotations of the space and the number of elements in the
% space.
% DEPRECATED : Use mortar.common.Spaces instead

switch(dim)
    case 'row'
        space_file = mortar.common.Spaces.probe_space(space);
        space_file = space_file{1};
        annot = '';
        nel = nan;
    case 'column'
        spaces = parse_tbl(fullfile(mortarpath, 'resources/spaces.txt'),...
                'verbose', false);
        csidx = strcmp(spaces.id, sprintf('column_%s_%s', space, build_id));
        assert(any(csidx), 'invalid column space: %s for build_id %s',...
            space, build_id);
        space_file = spaces.space_file{csidx};
        annot = spaces.annot_file{csidx};
        nel = spaces.numel(csidx);
end

end