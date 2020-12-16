function [h, joint_rpt, rpt1_filt, rpt2_filt] = compareRecall(rpt1, rpt2, gp_field)

n1 = length(rpt1);
n2 = length(rpt2);
[gpv1, gpn1, gpi1] = get_groupvar(rpt1, [], gp_field);
[gpv2, gpn2, gpi2] = get_groupvar(rpt2, [], gp_field);

[c, ia, ib] = intersect(gpv1, gpv2);
if ~isequal(length(c), min(n1, n2))
    warning('Groups with duplicates found, ignoring duplicates');
end

rpt1_filt = rpt1(ia);
rpt2_filt = rpt2(ib);
score1 = [rpt1_filt.score]';
score2 = [rpt2_filt.score]';

col_rank1 = [rpt1_filt.col_rank]';
col_rank2 = [rpt2_filt.col_rank]';
delta_rank = abs(col_rank1 - col_rank2)./min(col_rank1, col_rank2);
rpt1_filt = setarrayfield(rpt1_filt,[],'delta_rank', delta_rank);
rpt2_filt = setarrayfield(rpt2_filt,[],'delta_rank', delta_rank);

n = length(c);

figure;
plot([-3, 3], [-3, 3], 'k--');
hold on
h1 = scatter(score1, score2, 25, log2(delta_rank), 'filled');
set(h1, 'markeredgecolor', ones(1,3)*0.4)
axis square
ylim([-3 3])
xlim(ylim)
caxis([0 5]);
colorbar
colormap(flipud(parula(6)*0.9));
title(sprintf('n=%d', n))
h = [h1];

res = keepfield(rpt1_filt, {'row_pert_id','row_pert_iname','row_pert_idose','score','col_rank'});
res = setarrayfield(res, [], 'id', num2cell(1:n));
res2 = keepfield(rpt2_filt, {'score','col_rank', 'delta_rank'});
res2 = setarrayfield(res2, [], 'id', num2cell(1:n));
res2 = mvfield(res2, {'score','col_rank'},{'score_2', 'col_rank_2'});
joint_rpt = join_table(res, res2, 'id', 'id');
joint_rpt = orderfields(joint_rpt, orderas(fieldnames(joint_rpt),...
    {'id'}));
[~, ord] = sort([joint_rpt.delta_rank]');
joint_rpt = joint_rpt(ord);
end