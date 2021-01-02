function list = find_file_by_index(index_file, result_path, out_path)
% FIND_FILE_BY_INDEX Finds files accoring to wildcards listed in a file

tbl = parse_tbl(index_file);

nrec = length(tbl.group);
tbl.url = cell(nrec, 1);

% find urls
for ii=1:nrec
    [fn, fp] = find_file(fullfile(result_path, tbl.location{ii}, tbl.wildcard{ii}));    
    if ~isempty(fp)
        tbl.url{ii} = path_relative_to(out_path, fp);
        % deal with multiple matches
        idx = ones(numel(fp),1)*ii;
        tbl.group{ii} = tbl.group(idx);
        tbl.action{ii} = tbl.action(idx);        
        % missing a name, use filename instead
        if isempty(tbl.name{ii})
            tbl.name{ii} = fn;
        else
            tbl.name{ii} = tbl.name(idx);
        end
        % append dim
        if ~isequal(tbl.add_dim{ii}, 'n')
            for jj=1:length(fn)
                [nr, nc] = get_filedim(fn{jj});
                switch(tbl.add_dim{ii})
                    case 'nrow'
                        if ~isempty(nr)
                            tbl.name{ii}{jj} = sprintf(tbl.name{ii}{jj}, nr);
                        end
                    case 'ncol'
                        if ~isempty(nc)
                            tbl.name{ii}{jj} = sprintf(tbl.name{ii}{jj}, nc);
                        end
                        
                    case 'ndim'
                        if ~isempty(nr) && ~isempty(nc)
                            tbl.name{ii}{jj} = sprintf(tbl.name{ii}{jj}, nr, nc);
                        end
                end
            end
        end
        
    else
        % missing, so enter blanks
        % will be removed on cat
        tbl.group{ii} = {};
        tbl.name{ii} = {};
        tbl.action{ii} = {};
        tbl.url{ii} = {};
    end
end

list = struct('group', cat(1,tbl.group{:}), 'url', cat(1, tbl.url{:}),...
            'name', cat(1, tbl.name{:}), 'action', cat(1, tbl.action{:}));
        
end