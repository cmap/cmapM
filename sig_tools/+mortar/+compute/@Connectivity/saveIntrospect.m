function saveIntrospect(res, out_path, use_gctx)
% saveIntropspect Save introspect results.
% saveIntrospect(res, out_path, use_gctx)

if ~use_gctx
    gct_writer = @mkgct;
else
    gct_writer = @mkgctx;
end

if ~isdirexist(out_path)
    mkdir(out_path);
end

% save arguments
% print_args('runIntrospect', fullfile(out_path, 'params.txt'), res.args);

% save genesets
mkgmt(fullfile(out_path, 'up.gmt'), res.up);
mkgmt(fullfile(out_path, 'dn.gmt'), res.dn);

% save result matrices
result_fields = {'cs', 'ncs', 'ps', 'ps_bkg'};
for ii=1:length(result_fields)
    if isfield(res, result_fields{ii}) && isds(res.(result_fields{ii}))
        out_file = fullfile(out_path, sprintf('%s.gctx', result_fields{ii}));
        gct_writer(out_file, res.(result_fields{ii}));
    end
end

end
