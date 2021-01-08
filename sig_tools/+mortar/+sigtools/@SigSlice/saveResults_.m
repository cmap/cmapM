function saveResults_(obj, out_path)
required_fields = {'args', 'ds'};
res = obj.getResults;
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end
% save results
if ~isempty(res.ds.src) || ~strcmp('unamed', res.ds.src)
    [~, fn, ext] = fileparts(res.ds.src);
    out_file = [fn, ext];
else
    out_file = 'subset.gctx';
end

if res.args.use_gctx
    mkgctx(fullfile(out_path, out_file), res.ds)
else
    mkgct(fullfile(out_path, out_file), res.ds, 'precision', res.args.num_digits);
end

end