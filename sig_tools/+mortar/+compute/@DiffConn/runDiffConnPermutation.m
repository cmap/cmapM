function runDiffConnPermutation(ps, pheno, nperm, row_meta, out_path)
% runDiffConnPermutation Run diff conn analysis with permuted phenotypes
% Permute phenotypes and Generate background stats
% Inputs:
% connectivity matrix
% phenotype definition

pheno_all = parse_record(pheno);
% % keep only phenotype selections
% is_pick = abs([pheno_all.phenotype_vec]')>0;
% pheno = pheno_all(is_pick);

ps_annot = parse_gctx(ps, 'annot_only', true);
col_meta = gctmeta(ps_annot);
row_meta = parse_record(row_meta);

mkdirnotexist(out_path);

%%
[gp_name, gp_idx] = getcls({pheno_all.pert_iname}');
ngp = length(gp_name);
row_space = {row_meta.id}';
nfeature = length(row_space);
for ii=1:ngp
    dbg(1, '%d/%d %s', ii, ngp, gp_name{ii});
    this = gp_idx==ii;
    this_pheno = pheno_all(this);
    num_rec = length(this_pheno);
    num_pos = nnz([this_pheno.phenotype_vec]'>0);
    num_neg = nnz([this_pheno.phenotype_vec]'<0);
    % phenotype vector for permuted samples
    perm_pheno_vec = [ones(num_pos, 1); -ones(num_neg, 1)]';
    % read all columns(cell lines) for this group
    [this_cid, ia, ib] = intersect({this_pheno.sig_id}', {col_meta.cid}', 'stable');
    this_ps = parse_gctx(ps, 'cid', this_cid);
    % filter to row_space
    this_ps = ds_slice(this_ps, 'rid', row_space);
    
    this_ps = annotate_ds(this_ps, row_meta, 'dim', 'row', 'keyfield', 'id');
    % Connectivity in positive class
    this_pos_q = zeros(nperm, nfeature);
    % Connectivity in the negative class
    this_neg_q50 = zeros(nperm, nfeature);
    % samples used in the phenotype (indices into thie_pheno
    this_pheno_idx = zeros(num_pos + num_neg, nperm);
    for jj=1:nperm
        % generate permuted phenotype
        perm_idx = randsample(num_rec, num_pos + num_neg);        
        this_perm = this_pheno(perm_idx);
        
        this_perm = setarrayfield(this_perm, [], 'phenotype_vec', perm_pheno_vec);
        [this_cid, ia, ib] = intersect({this_perm.sig_id}', {col_meta.cid}', 'stable');
        perm_ps = ds_slice(this_ps, 'cid', this_cid);
        perm_ps = annotate_ds(perm_ps, this_perm, 'keyfield', 'sig_id', 'append', false);
        dc_metrics = mortar.compute.DiffConn.diffConnMetrics(perm_ps, 'phenotype_vec');
        this_pheno_idx(:, nperm) = perm_idx;
        this_pos_q(jj, :) = [dc_metrics.pos_q]';
        this_neg_q50(jj, :) = [dc_metrics.neg_q50]';
    end
    
    % save permuted stats
    ds_pos_q = mkgctstruct(this_pos_q, 'rid', gen_labels(nperm), 'cid', row_space);
    ds_neg_q50 = mkgctstruct(this_neg_q50, 'rid', gen_labels(nperm), 'cid', row_space);
    
    
    
    ds_pheno_idx = mkgctstruct(this_pheno_idx,...
        'rid', strcat(gen_labels(length(perm_pheno_vec)),...
        num2cellstr(perm_pheno_vec)), 'cid', gen_labels(nperm));
    out_pos_q = fullfile(out_path, sprintf('%s_pos_q.gctx', gp_name{ii}));
    mkgctx(out_pos_q, ds_pos_q)
    out_neg_q50 = fullfile(out_path, sprintf('%s_neg_q50.gctx', gp_name{ii}));
    mkgctx(out_neg_q50, ds_neg_q50)
    out_sample_info = fullfile(out_path, sprintf('%s_sample_info.txt', gp_name{ii}));
    jmktbl(out_sample_info, this_pheno);
    out_pheno_idx = fullfile(out_path, sprintf('%s_pheno_idx.gctx', gp_name{ii}));
    mkgctx(out_pheno_idx, ds_pheno_idx)
end
end