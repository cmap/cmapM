function ops_table = generate_ops_table(table, params)
    num_entries_per_param = ones(1, numel(params));     
    param_options = cell(1, numel(params));
    for i=1:numel(params)
        if isnumeric([table.(params{i})])
            param_options{i} = num2cell(unique([table.(params{i})]));
            num_entries_per_param(i) = numel(unique([table.(params{i})]));
        else
            param_options{i} = unique({table.(params{i})});
            num_entries_per_param(i) = numel(unique({table.(params{i})}));
        end
    end
    
    
    ncomb = 1;
    nparams = numel(num_entries_per_param);
    for i=1:nparams
        ncomb = ncomb * num_entries_per_param(i);
    end
    
    idx_arr = cell(1,nparams);
    for i=1:nparams
        idx_arr{i} = [1:num_entries_per_param(i)];
    end
    
    idx_ph= cell(1,nparams);
    [idx_ph{:}] = ndgrid(idx_arr{:});
    idx_combs = cellfun(@(m) m(:), idx_ph, 'uni', 0);
    
    
    ops_table = cell(numel(idx_combs{1}), numel(params));
    for i=1:numel(idx_combs)
        if isnumeric([param_options{i}{idx_combs{i}}])
            ops_table(1:numel(idx_combs{i}), i) = param_options{i}(idx_combs{i});
        else
            ops_table(1:numel(idx_combs{i}), i) = param_options{i}(idx_combs{i});
        end    
    end

end

