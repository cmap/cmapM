function saveResults_(obj, out_path)
required_fields = {'args', 'introspect_result'};
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% Save Introspect results
args = obj.getArgs;
mortar.compute.Connectivity.saveIntrospect(res.introspect_result, ...
    out_path, args.use_gctx);

end