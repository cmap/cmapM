function res = unwrap_table(tblfile, fn, dlm, varargin)
% UNWRAP_TABLE Split field values of table with concatenated fields.
% RES = UNWRAP_TABLE(TBL, FN, DLM) Tokenizes the field FN of table TBL
% using the delimiter DLM and returns a table RES that contains a new row
% for each token.

tbl = parse_tbl(tblfile, 'outfmt', 'record', varargin{:});
assert(isfield(tbl, fn), 'Field not found : %s', fn);

fv = {tbl.(fn)}';
if isempty(dlm)
    fn_val = cat(1, fv{:});
    ntok = cellfun(@length, fv);
else
    tok = tokenize(fv, dlm);
    fn_val = cat(1, tok{:});
    ntok = cellfun(@length, tok);
end

csum = cumsum(ntok);
idx = zeros(csum(end), 1);
idx([1; csum(1:end-1)+1]) = 1;
cumi = cumsum(idx);
res = tbl(cumi);
[res.(fn)] = fn_val{:};

end