function tag = get_process_code(tag, process, alg, varargin)

pnames = {'codes'};
dflts = {fullfile(mortarconfig('l1k_config_path'), 'process_codes.txt')};
args = parse_args(pnames, dflts, varargin{:});

code_table = parse_tbl(args.codes);

if ischar(tag)
    tag = {tag};
end
if all(cellfun(@isempty, tag))
    res = get_tag(code_table, process, alg);
    tag(:) = res.code;
else
    [cn, nl] = getcls(tag);
    
    for ii=1:length(cn)
        tok = tokenize(cn{ii}, '+');
        res = get_tag(code_table, process, alg);
        if ~ismember(res.code, tok{1})
            tag(nl==ii) = regexprep(strcat(tag(nl==ii), '+', res.code),'^\+', '');
        end
    end
end

end

function res = get_tag(code_table, process, alg)
if ~isequal(process, 'brew')
    res = filter_table(code_table, {'process', 'algorithm'}, {process, alg});
    assert(~isempty(res.process), 'Unknown alg: %s:%s', process, alg);    
else
    group_code = filter_table(code_table, {'process'}, {process});
    gp = lower(tokenize(alg, ','));
    ngp = length(gp);
    gpdict = list2dict(group_code.algorithm);
    for ii=1:ngp
        if gpdict.isKey(gp{ii})
            gp(ii) = group_code.code(gpdict(gp{ii}));
        end
    end
    res.code = {sprintf('GB%s', print_dlm_line(gp, 'dlm', ','))};
end
end