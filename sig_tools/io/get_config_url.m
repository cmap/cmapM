function cfg = get_config_url(cfg, outPath, overwrite, encode_str)
% GET_CONFIG_URL Get URLS from fields in a config structure.

if ~isvarexist('overwrite')
    overwrite = false;
end
if ~isvarexist('encode_str')
    encode_str = false;
end
fn = fieldnames(cfg);
isstring = structfun(@(x) isequal(class(x), 'char'), cfg);
ns = nnz(isstring);
sfn = fn(isstring);
for ii=1:ns
    this_string = cfg.(sfn{ii});    
    ut = uri_type(this_string);
    % save locally if file is remote
    if ~isempty(ut) && ~isequal(ut, 'file')    
        outFile = urlget(this_string, outPath, overwrite, encode_str);
        cfg.(sfn{ii}) = outFile;            
    end
end

end