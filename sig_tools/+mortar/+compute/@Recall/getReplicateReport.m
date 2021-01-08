function [rep_recall_rpt, rep_stats_rpt] = getReplicateReport(pair_recall_rpt, outlier_alpha)
% Summary report per unique replicate(X1, X2 etc)

recall_metric = pair_recall_rpt(1).recall_metric;
recall_score = [[pair_recall_rpt.recall_score]'; [pair_recall_rpt.recall_score]'];
recall_rank = [[pair_recall_rpt.recall_rank]';[pair_recall_rpt.recall_rank]'];
recall_composite = [[pair_recall_rpt.recall_composite]'; [pair_recall_rpt.recall_composite]'];
replicate_id = [{pair_recall_rpt.ds1_name}'; {pair_recall_rpt.ds2_name}'];
[cn, nl] = getcls(replicate_id);
%uniq_replicate_name = get_tokens(cn, 4, 'dlm', '_');
% toks = tokenize(cn, '_');
% toks = horzcat(toks{:})';
% 
% idx = false(1,size(toks,2));
% for i = 1:size(toks, 2)
% idx(i) = numel(unique(toks(:,i))) > 1;
% end
% uniq_vals = get_tokens(cn, find(idx), 'dlm', '_');
% 
% uniq_replicate_name = cell(size(uniq_vals, 1), 1);
% for i = 1:size(uniq_vals, 1)
%     uniq_replicate_name{i} = strjoin(uniq_vals(i,:), '_');
% end
% 
% 
% % 
% nuniq_name = length(unique(uniq_replicate_name));
% if isequal(nuniq_name, length(cn))
%     replicate_name = uniq_replicate_name(nl);
% else
%     [~, bf] = basename(replicate_id);
%     replicate_name = strip_dimlabel(bf);
% end
[~, bf] = basename(replicate_id);
replicate_name = strip_dimlabel(bf);
max_rank = max([pair_recall_rpt.max_rank]);

rep_recall_rpt = struct('replicate_id', replicate_id,...
       'replicate_name', replicate_name,...
       'recall_metric', recall_metric,...
       'recall_score', num2cell(recall_score),...
       'recall_rank', num2cell(recall_rank),...
       'recall_composite', num2cell(recall_composite),...
       'max_rank', max_rank);

rep_stats_rpt = mortar.compute.Recall.detectOutlierReplicates(recall_rank,...
                replicate_id, 'alpha', outlier_alpha, 'is_low_good', true);
[~, ia] = intersect({rep_recall_rpt.replicate_id}, {rep_stats_rpt.replicate_id}', 'stable');
rep_stats_rpt = setarrayfield(rep_stats_rpt, [], {'replicate_name'}, {rep_recall_rpt(ia).replicate_name}');
rep_stats_rpt = orderfields(rep_stats_rpt, orderas(fieldnames(rep_stats_rpt),...
                    {'replicate_id', 'replicate_name'}));
end