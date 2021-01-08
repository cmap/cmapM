function [h, recall_stats] = plotRecallByGroup(recall_rpt, gp_field, showfig)
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(recall_rpt, [], gp_field);

ngroup = length(gpn);
h = cell(4, 1);
group_struct = struct('group_name', gpn);
% gp, max_rank, col_rank_1pct, col_rank_5pct, col_rank_10pct 
for ii=1:ngroup
    disp(gpn{ii});
    this = gpi==ii;
    this_rpt = recall_rpt(this);
    [h, this_stats] = mortar.compute.Connectivity.plotRecall(this_rpt, showfig, h);
    recall_stats(ii) = mergestruct(group_struct(ii), this_stats);
end
for ii=1:length(h)
    myfigure(showfig, h(ii))
    hl = findobj(gca, 'type', 'stair');
    legend(hl, gpn, 'location', 'southeast')
end

end

