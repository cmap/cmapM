function saveResults_(obj, out_path)
required_fields = {'args'};
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end
    if ~isempty(res.up)
        mkgmt(fullfile(out_path, sprintf('up_n%d.gmt', res.nsets)), res.up);
    end
    if ~isempty(res.dn)
        mkgmt(fullfile(out_path, sprintf('down_n%d.gmt', res.nsets)), res.dn);
    end

    
end

% save results
% CREATE RESULT FILES AND REPORTS HERE

% mkgctx(fullfile(out_path, 'result.gctx'), res.ds);

% generate plots
% ADD PLOTTING ROUTINES HERE

% Save figures and close them
% savefigures('out', 'outpath', 'mkdir', false, 'closefig', true);