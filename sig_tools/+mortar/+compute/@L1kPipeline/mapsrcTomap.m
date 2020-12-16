function mapList = mapsrcTomap(plates, map_src_path)

plates = parse_grp(plates);
nplate = length(plates);

mapList = cell(nplate, 1);
for ii=1:nplate
    mapList{ii} = genOneMap(plates{ii}, map_src_path);
end

end

function map = genOneMap(plate_name, map_src_path)

pp = plateparts(plate_name);
map_src_file = fullfile(map_src_path, sprintf('%s.src', pp.pert_plate));
map_src = parse_record(map_src_file);

rna_plate = sprintf('%s_%s_%s_%s', pp.pert_plate, pp.cell_id, pp.pert_time, pp.rep_id);

pert_time = strrep(pp.pert_time, 'H', '');
pert_time_unit = 'H';
pert_itime = sprintf('%s %s', pert_time, pert_time_unit);
cell_id = pp.cell_id;

map_src = mvfield(map_src, {'pert_plate', 'pert_well'}, {'rna_plate', 'rna_well'});
map = setarrayfield(map_src, [],...
            {'rna_plate', 'cell_id', 'pert_time',...
            'pert_time_unit', 'pert_itime'},...
            rna_plate, cell_id, pert_time,...
            pert_time_unit, pert_itime);


end

