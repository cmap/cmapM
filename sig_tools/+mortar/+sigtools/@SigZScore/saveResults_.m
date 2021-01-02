function saveResults_(obj, out_path)
required_fields = {'args'};
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% save results
if res.args.use_gctx
    mkgctx(fullfile(out_path, 'result.gctx'), res.output);
else
    mkgct(fullfile(out_path, 'result.gctx'), res.output);
end
