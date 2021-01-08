function saveResults_(obj, out_path)
required_fields = {'args', 'sig', 'full_score', 'up_set', 'dn_set', ...
                  'cl_discarded'};
res = obj.getResults;
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

if res.args.use_gctx
    gctwriter=@mkgctx;
else
    gctwriter=@mkgct;
end

% save arguments
% print_args('MarkerSelection', fullfile(out_path, 'params.txt'), res.args);
nres = length(res.sig);

if ~isempty(res.cl_discarded)
    mktbl(fullfile(out_path, 'phenotypes_ignored.txt'), res.cl_discarded);
end

% full matrix and sets
full_out = fullfile(out_path, 'matrices');
if ~isdirexist(full_out)
    mkdir(full_out);
end

index = res.stats;
nsig = numel(res.full_score.cid);
gctwriter(fullfile(full_out, 'sig_score.gct'), res.full_score);
mkgmt(fullfile(full_out, sprintf('sig_up_n%dxs%d.gmt', nsig, res.args.nmarker)), res.up_set);
mkgmt(fullfile(full_out, sprintf('sig_dn_n%dxs%d.gmt', nsig, res.args.nmarker)), res.dn_set);

if (~res.args.skip_rpt)
    for ii=1:nres
        this_out = fullfile(out_path, res.sig(ii).sig_id);
        if ~isdirexist(this_out)
            mkdir(this_out)
        end
        mktbl(fullfile(this_out, 'phenotype.txt'), res.sig(ii).phenotype);
        gctwriter(fullfile(this_out, 'score.gct'), res.sig(ii).score_ds);
        marker_file = gctwriter(fullfile(this_out, 'marker_ds.gct'), res.sig(ii).marker_ds);    
        %heatmap
        class_fields = {'class_label', 'class_id'};
        f = class_fields(find(ismember(class_fields, res.sig(ii).marker_ds.chd),1,'first'));
        class_field = ifelse(~isempty(f), f, class_fields{1});
        ofname = createHeatmap(marker_file, res.sig(ii).sig_id, this_out, class_field, res.args.add_heatmap_fields);    
        index(ii).url = ofname; 
    end
end

mktbl(fullfile(full_out, 'sig_stats.txt'), index);

field_order = orderas(fieldnames(index),...
                {'cid', 'strength', 'num_fc_ge2',...
                'num_a','num_b','class_a','class_b'});
index = orderfields(index, field_order);
% Generate index.html
mk_html_table(fullfile(out_path, 'index.html'), index,...
    'title', 'Sig Marker Tool');


end

function [ofname, status, result] = createHeatmap(marker_file, prefix, wkdir, class_field, add_fields)
row_fields = {'id', 'pr_gene_symbol', 'cell_iname', 'score',...
    'lfc', 'mean_a', 'mean_b',...
    'std_a', 'std_b'};
if ~isempty(add_fields)
    add_fields = tokenize(add_fields, ',', true);
    row_fields = union(row_fields, add_fields, 'stable');
end

[ofname, status, result] = mkheatmap(marker_file, fullfile(wkdir,...
    'heatmap.png'),...
    'row_text', row_fields,...
    'column_color', class_field,...
    'title', prefix);
if ~isequal(status, 0)
    warning('Unable to create heatmap: %s\n%s',ofname, result);
end
end
