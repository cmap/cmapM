function saveResults_(obj, out_path)
required_fields = {'args', 'recall_stats'};
args = obj.getArgs;
res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

% save results
% CREATE RESULT FILES AND REPORTS HERE
main_index = fullfile(out_path, 'index.html');
main_index_text = fullfile(out_path, 'index.txt');
fn = fieldnames(res.recall_stats);
main_table = keepfield(res.recall_stats, fn(~rematch(fn, '_thresh_')));
% save the index as text to enable tweaks
jmktbl(main_index_text, main_table);

mk_html_table(main_index, main_table)

end