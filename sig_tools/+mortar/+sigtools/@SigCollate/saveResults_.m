function saveResults_(obj, out_path)
required_fields = {'args', 'out_file', 'file_list'};
res = obj.getResults;
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% save results
nfile = length(res.file_list);
list_file = fullfile(out_path, sprintf('filelist_n%d.grp', nfile));
mkgrp(list_file, res.file_list);

% rename gctx
annot = parse_gctx(res.out_file, 'annot_only', true);
nr = numel(annot.rid);
nc = numel(annot.cid);
new_file = add_dim(res.out_file, nr, nc);
movefile(res.out_file, new_file);
res.out_file = new_file;
obj.res_ = res;

end