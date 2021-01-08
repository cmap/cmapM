function saveResults_(obj, out_path)
required_fields = {'args'};
res = obj.getResults;                
ismem = isfield(res, required_fields);

if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

[~,fn] = fileparts(res.args.ds);

outname = strip_dimlabel(fn);

fp = fullfile(out_path, sprintf('%s_INF.gctx', outname));

gctwriter = ifelse(res.args.use_gctx, @mkgctx, @mkgct);
gctwriter(fp, res.output);
 