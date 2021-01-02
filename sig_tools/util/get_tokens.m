function res = get_tokens(s, idx, varargin)
% GET_TOKENS Extract delimited substrings from a cell array
% R = GET_TOKENS(S, IDX)
% R = GET_TOKENS(S, IDX, 'param', 'value'...)
% 'dlm': character, delimiter. Default is ':'
% 'missing_value': string, Default is '-666'

pnames = {'dlm', 'missing_value'};
dflts = {':', '-666'};
args = parse_args(pnames, dflts, varargin{:});

assert(isvector(s), 'Input must be a string or 1-d cell array');
[tok, nt] = tokenize(s, args.dlm, true);
%nt = cellfun(@numel, tok);
min_idx = min(idx);
max_idx = max(idx);
in_range = max_idx <= nt & min_idx >= 1;
if all(in_range)
    has_missing = false;
else
    has_missing = true;
end

nidx = length(idx);
nr = length(nt);
if isequal(nr, 1) && length(tok)>1
    tok = {tok};
end
res = cell(nr, nidx);
for ii=1:nidx    
    if has_missing
        keep = idx(ii)<=nt & idx(ii)>=1;
        res(keep, ii) = cellfun(@(x) x{idx(ii)}, tok(keep), 'unif', false);
        res(~keep, ii) = {args.missing_value};
    else
        res(:, ii) = cellfun(@(x) x{idx(ii)}, tok, 'unif', false);
    end
end

end