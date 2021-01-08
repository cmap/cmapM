function rpt = tally(cell_array, show_results)
% TALLY count frequency of occurrence of items in a list
%   S = TALLY(L)

if ~isvarexist('show_results')
    show_results = true;
end

if isnumeric(cell_array)
    is_num = true;
    miss_val = -666;
    ie = isnan(cell_array);
    cell_array(ie) = miss_val;
else
    is_num = false;
    miss_val = 'MISSING';
    ie = cellfun(@isempty, cell_array);
    cell_array(ie) = {miss_val};
end


[cn, nl] = getcls(cell_array);
sz = accumarray(nl, ones(size(nl)));

if isnumeric(cn)
    cn = num2cell(cn);
end
rpt = struct('group', cn,...
       'group_size', num2cell(sz));

if show_results
    disp(struct2table(rpt));
end

end