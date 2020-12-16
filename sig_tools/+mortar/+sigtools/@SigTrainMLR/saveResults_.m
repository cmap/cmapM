function saveResults_(obj, out_path)
required_fields = {'args'};
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end
toolName = 'trainMLR';
% wkdir = mkworkfolder(out_path, toolName);
% fprintf('Saving analysis to %s\n', wkdir);

%Parameters
fid = fopen(fullfile(out_path, sprintf('%s_params.txt', toolName)), 'wt');
print_tool_params2(toolName, fid, res.args);
fclose (fid);

model = res.output;

ds = mkgctstruct(model.mat, 'rid', model.rn, 'cid', model.cn);

table = struct('cid', ds.cid, 'modeltype', res.args.modeltype, ...
    'grp_landmark', res.args.grp_landmark);

model = annotate_ds(ds, table);

%extract prefix from training set
[r,c] = size(model.mat);
switch res.args.outfmt
    case 'mat'
        modelfile = fullfile(out_path, sprintf('model_n%dx%d.mat', c, r));
        fprintf ('Saving model to %s\n', modelfile);
        save(modelfile, 'model');
    case 'gct'
        modelfile = fullfile(out_path, sprintf('model_n%dx%d.gct', c, r));
        fprintf ('Saving model to %s\n', modelfile);
        mkgct(modelfile, model, 'matrix_class', 'double');
    case 'gctx'
        modelfile = fullfile(out_path, sprintf('model_n%dx%d.gct', c, r));
        fprintf ('Saving model to %s\n', modelfile);
        mkgctx(modelfile, model, 'matrix_class', 'double');
    otherwise
        error('Invalid output type');
end