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

% mkgctx(fullfile(out_path, 'result.gctx'), res.ds);

% generate plots
% ADD PLOTTING ROUTINES HERE

% Save figures and close them
% savefigures('out', 'outpath', 'mkdir', false, 'closefig', true);