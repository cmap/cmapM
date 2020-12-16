function [out_gmt, unmapped_gmt] = mapGeneWithChipFile(chip_file, in_gmt, from_id, to_id)
% mapGeneWithChip Apply supplied chip file to perform gene mapping
% [out_gmt, unmapped_gmt] = mapGeneWithChip(chip_platform, chip_space, in_gmt, from_id, to_id)

chip = parse_record(chip_file, 'detect_numeric', false);
assert(all(isfield(chip, {from_id, to_id})),...
    'Required fields not found in chip file');

from_val = {chip.(from_id)}';
to_val = {chip.(to_id)}';

[from_gp, to_gp] = group2cell(to_val, from_val);

inid2outid = mortar.containers.Dict(from_gp, to_gp);
in_tbl = gmt2tbl(in_gmt);
all_inid = {in_tbl.member_id}';
isk = inid2outid.isKey(all_inid);
if any(isk)
    out_id = cell(numel(all_inid), 1);
    out_id(isk) = inid2outid(all_inid(isk));
    [in_tbl.out_id] = out_id{:};
    in_tbl_mapped = in_tbl(isk);
    in_tbl_mapped = unwrap_table(in_tbl_mapped, 'out_id', {});
    out_gmt = tbl2gmt(in_tbl_mapped, 'member_field', 'out_id');
    if any(~isk)
        unmapped_gmt = tbl2gmt(in_tbl(~isk));
    else
        unmapped_gmt = mkgmtstruct({},{},{});
    end
    
%     % table with features
%     uinid = unique(all_inid(isk));
%     chip_idx = inid2outid.isKey(uinid);
%     feature_map = chip(chip_idx);
else
    out_gmt = mkgmtstruct({},{},{});
    unmapped_gmt = in_gmt;
end

end