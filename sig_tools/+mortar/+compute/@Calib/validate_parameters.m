%Ensure parameters are field in siginfo table and print unique values
%for each parameter
function exp_params = validate_parameters(siginfo_table, list, prt) %separate exp_params and sub_fields
    if ~iscell(list)
        list = {list};
    end
    nparams = length(list);
    exp_params = cell(nparams,1);
    for i = 1:nparams
        if ~isfield(siginfo_table, list(i))
            dbg(prt, 'Parameter %s is not a field in provided siginfo \n', list{i});
        else
            if (iscellstr({siginfo_table.(list{i})}))
                field_vals = unique({siginfo_table.(list{i})});
                dbg(prt, 'Parameter %s has %d entries:',list{i}, length(field_vals));
                for j = 1:length(field_vals)
                   dbg(prt, '%s', field_vals{j});
                end
            else
                field_vals = unique([siginfo_table.(list{i})]);
                dbg(prt, 'Parameter %s has %d entries: \n',list{i}, length(field_vals));
                for j = 1:length(field_vals)
                   dbg(prt, '%d', field_vals(j));
                end
            end
            exp_params(i) = list(i);
        end
    end
    exp_params= exp_params(~cellfun('isempty', exp_params));     %trims empty cells
end