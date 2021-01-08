function prefix = brd_shorten(pert_id)
% BRD_SHORTEN generate shortened structure ids

if ischar(pert_id)
    pert_id = {pert_id};
end
prefix = pert_id;
is_brd = strncmp(pert_id, 'BRD-', 4);
prefix(is_brd) = cellfun(@(x) sprintf('BRD-%s',...
            x(length(x)-3:end)),...
            strrep(brd_prefix(pert_id(is_brd)), 'BRD-', ''),...
            'unif', false);

end