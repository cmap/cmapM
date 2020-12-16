function truncated_ids = truncate_ids(input_ids, varargin)
% TRUNCATE_IDS given a cell array of token containing ids,
% remove the last nremove tokens from each element

pnames = {'dlm', 'nremove'};
dflts = {':', 1};
args = parse_args(pnames, dflts, varargin{:});

truncated_ids = cellfun(@(x) truncate(x, args.dlm, args.nremove), input_ids);

function truncated = truncate(input_id, token, nremove)
	toks = tokenize(input_id, token);
	trun_toks = toks(1:end-nremove);
	truncated = paste(trun_toks', token);
end


end