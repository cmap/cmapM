function rpt = uniqify_table(tbl, gp_field, keep_field)
%Select unique rows from a table
tbl = parse_record(tbl);
if ~isvarexist('keep_field')
    keep_field = fieldnames(tbl);
end
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(tbl, fieldnames(tbl), gp_field, 'no_space',true);
[~, uidx] = unique(gpi, 'stable');
rpt = tbl(uidx);
[rpt.id] = gpn{:};
rpt = keepfield(rpt, [{'id'}; keep_field(:)]);

end