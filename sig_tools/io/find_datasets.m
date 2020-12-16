function [file, filepath, desc] = find_datasets(p, varargin)

pnames = {'folder_type'};
dflts = {''};
args = parse_args(pnames, dflts, varargin{:});

tbl = parse_tbl(fullfile(mortarconfig('l1k_config_path'), 'data_types.txt'),...
    'verbose',false);

nt = length(tbl.name);

isfound = false(nt, 1);
file = cell(nt, 1);
filepath = cell(nt, 1);
for ii=1:nt    
    if isempty(args.folder_type) || isequal(args.folder_type, tbl.folder_type{ii})
        [fn, fp] = find_file(fullfile(p, tbl.wildcard{ii}));
        if ~isempty(fn)
            file(ii) = fn(1);
            filepath(ii) = fp(1);
            isfound(ii) = true;
        end
    end
end

file(~isfound) = [];
filepath(~isfound) = [];
desc = tbl.name(isfound);

end