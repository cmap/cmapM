function res = wrap_table(tblfile, fn, make_unique)
% WRAP_TABLE Concatenate field values of table in long form.

if ~isvarexist('make_unique')
    make_unique = false;
end

tbl = parse_tbl(tblfile, 'outfmt', 'record');
fields = fieldnames(tbl);
field_lut = mortar.containers.Dict(fields);
assert(isfield(tbl, fn), 'Field not found : %s', fn);
fn_val = {tbl.(fn)}';
[gp, igp] = getcls(fn_val);
ngp = numel(gp);
nfields = numel(fields);
newval = cell(ngp, nfields);
newval(:, field_lut(fn)) = gp;
res = cell2struct(newval, fields, 2);
towrap = setdiff(fields, fn, 'stable');
nwrap = numel(towrap);
for ii=1:ngp
    this = igp==ii;
    c = struct2cell(tbl(this));
    for jj=1:nwrap
        idx = field_lut(towrap{jj});
        el = c(idx, :);
        if make_unique
            is_num = any(cellfun(@isnumeric_type, el));
            if is_num
                el = cellfun(@num2cellstr, el);
            end
            el = unique(el, 'stable');
        end
        s = print_dlm_line(el, 'dlm', '|');
        res(ii).(towrap{jj}) = s;
    end
end
res = orderfields(res, orderas(fields, fn));
end