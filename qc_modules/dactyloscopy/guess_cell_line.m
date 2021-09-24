function out = guess_cell_line(cell_array_w_strings, cell_array_w_substrings)

ns = length(cell_array_w_strings);
out =  cell(ns,2);

fprintf('%s> Number of strings to analyze: %d\n',mfilename,ns)
for ii = 1:ns
    fprintf('%s> Step: %d, Working on: %s\n', mfilename, ii, cell_array_w_strings{ii})
    out(ii,1) = cell_array_w_strings(ii);
    tmp = {cell_array_w_substrings(cellfun(@(s) ~isempty(s) ,...
        (cellfun(@(s) regexp(cell_array_w_strings(ii),strcat('^',s)),...
        cell_array_w_substrings))))};
    if length(tmp{:})>1
        [~,idxmaxl] = max(cellfun(@length, tmp{:}));
        tmp = tmp{:};
        out{ii,2} = tmp{idxmaxl};
    else
        if ~isempty(tmp{:})
            out(ii,2) = tmp{:};
        else
            out{ii,2} = 'empty';
        end
    end
end

out = out(cellfun(@(s) ~strcmp(s,'empty'),out(:,2)),:);