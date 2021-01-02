function saveResults_(obj, out_path)
required_fields = {'args'};
res = obj.getResults;                

ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% save results
% CREATE RESULT FILES AND REPORTS HERE

mortar.prism.curie.saveCurieResult(res.query_result, out_path, res.args.use_gctx, res.args.skip_key_as_text);

end
