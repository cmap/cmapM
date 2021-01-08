function saveResults_(obj, out_path)
required_fields = {'args', 'row_meta',...
                    'column_meta', 'ds',...
                    'is_updated'};
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% save results
if res.is_strip
    [~, out_file, ext] = fileparts(res.ds_strip.src);
    % use the input files format
    gctwriter = ifelse(strcmpi(ext, '.gctx'), @mkgctx, @mkgct);
    if isempty(out_file)
       out_file = 'dataset';
    end
    gctwriter(fullfile(out_path, out_file), res.ds_strip);
end

if res.is_updated
    [~, out_file, ext] = fileparts(res.ds.src);
    % use the input files format
    gctwriter = ifelse(strcmpi(ext, '.gctx'), @mkgctx, @mkgct);
    if isempty(out_file)
       out_file = 'dataset';
    end
    gctwriter(fullfile(out_path, out_file), res.ds);
else
    mktbl(fullfile(out_path,...
        sprintf('row_meta_n%d.txt', numel(res.row_meta))),...
        res.row_meta);
    mktbl(fullfile(out_path,...
        sprintf('column_meta_n%d.txt', numel(res.column_meta))),...
        res.column_meta);
end
end