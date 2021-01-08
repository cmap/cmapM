function diffconn_rpt = computeDiffConn(varargin)
% Inputs
% connectivity matrix (PS)
% phenotype field (binarized or float)
% column grouping variable
% diff conn thresholds

% outputs
% datamatrix cols=col_groups, rows=pert

[args, help_flag] = getArgs(varargin{:});
if ~help_flag    
    
    diffconn_rpt = diffConn(args);
    
end

end

function data_struct = diffConn(args)
    % compute diff conn analytic
    data_struct = loadData(args);
    gpv = data_struct.column_group;
    [gpn, gpi] = getcls(gpv);
    ngp = length(gpn);    
    phenotype_score = data_struct.phenotype_score;
    phenotype_label = data_struct.phenotype_label;
    nrow = size(data_struct.ds.mat, 1);
    diffconn_mat = nan(nrow, ngp);
    cc_mat = nan(nrow, ngp);
    ps_sens_mat = nan(nrow, ngp);
    fr_insens_mat = nan(nrow, ngp);
    col_meta = struct('cid', gpn,...
                      'num_sig', nan,...
                      'num_sens', nan,...
                      'num_insens', nan);
    for ii=1:ngp
        this_gp = gpi == ii;
        this_ps = ds_slice(data_struct.ds, 'cidx', this_gp);
        % Set nans to 0
        this_ps = ds_nan_to_val(this_ps, 0);
        this_pheno = phenotype_score(this_gp);
        this_sens = phenotype_label(this_gp);
        nsig = nnz(this_gp);
        nsens = nnz(this_sens);
        ninsens = nnz(~this_sens);        
        dbg(1, '%d/%d %s Num Sens: %d', ii, ngp, gpn{ii}, nsens);
        
        % Pearson correlation with phenotype score
        this_cc = fastcorr(this_pheno, this_ps.mat')';
        
        % Aggregate Connectivity in sens class
        ps_sens = max_quantile(this_ps.mat(:, this_sens), 10, 90, 2);
        ps_median = median(this_ps.mat, 2);
        ps_fc = ps_sens./ps_median;
        
        % Fraction of unaffecteds with strong connectivity
        fr_insens = sum(bsxfun(@times,...
            sign(ps_sens),...
            this_ps.mat(:, ~this_sens))>=...
            args.ps_insens_th, 2)/ninsens;
        is_diffcon = abs(ps_sens)>=args.ps_sens_th & fr_insens < args.fr_insens_th;
        
        cc_mat(:, ii) = this_cc;
        ps_sens_mat(:, ii) = ps_sens;
        fr_insens_mat(:, ii) = fr_insens;
        %diffconn_mat(:, ii) = this_cc.*is_diffcon;
        %diffconn_mat(:, ii) = this_cc .* (abs(ps_sens)/100) .* (1.01-fr_insens);
        diffconn_mat(:, ii) = abs(this_cc) .* ((ps_sens)/100);
        col_meta = setarrayfield(col_meta, ii,...
                                {'num_sig', 'num_sens', 'num_insens'},...
                                nsig, nsens, ninsens);
    end
    diffconn_ds = mkgctstruct(diffconn_mat,...
                              'rid', data_struct.ds.rid,...
                              'cid', gpn);
    cc_ds = mkgctstruct(cc_mat,...
                              'rid', data_struct.ds.rid,...
                              'cid', gpn);                          
    ps_sens_ds = mkgctstruct(ps_sens_mat,...
                              'rid', data_struct.ds.rid,...
                              'cid', gpn);
    fr_insens_ds = mkgctstruct(fr_insens_mat,...
                              'rid', data_struct.ds.rid,...
                              'cid', gpn);
                          
    row_meta = gctmeta(data_struct.ds, 'row');
    
    diffconn_ds = annotate_ds(diffconn_ds, col_meta, 'dim', 'column');
    diffconn_ds = annotate_ds(diffconn_ds, row_meta, 'dim', 'row');
    ps_sens_ds = annotate_ds(ps_sens_ds, col_meta, 'dim', 'column');
    ps_sens_ds = annotate_ds(ps_sens_ds, row_meta, 'dim', 'row');
    fr_insens_ds = annotate_ds(fr_insens_ds, col_meta, 'dim', 'column');
    fr_insens_ds = annotate_ds(fr_insens_ds, row_meta, 'dim', 'row');
    cc_ds = annotate_ds(cc_ds, col_meta, 'dim', 'column');
    cc_ds = annotate_ds(cc_ds, row_meta, 'dim', 'row');
        
    data_struct.diffconn_ds = diffconn_ds;
    data_struct.cc_ds = cc_ds;
    data_struct.ps_sens_ds = ps_sens_ds;
    data_struct.fr_insens_ds = fr_insens_ds;
end

function data_struct = loadData(args)
ds = parse_gctx(args.ds);

has_phenotype_score = ds.cdict.isKey(args.phenotype_score_field);
assert(has_phenotype_score, 'Phenotype score field %s not found', args.phenotype_score_field);
phenotype_score = ds_get_meta(ds, 'column', args.phenotype_score_field);

has_phenotype_label = ds.cdict.isKey(args.phenotype_label_field);
assert(has_phenotype_label, 'Phenotype label field %s not found', args.phenotype_label_field);
phenotype_label = ds_get_meta(ds, 'column', args.phenotype_label_field);

has_col_group = all(ds.cdict.isKey(args.column_group));
assert(has_col_group, 'Column group field %s not found', args.column_group);
col_gpv = get_groupvar(ds.cdesc, ds.chd, args.column_group);
% add grouping var as column field
ds = ds_add_meta(ds, 'column', 'diffconn_group', col_gpv);
data_struct = struct('ds', ds,...
                     'phenotype_score', {phenotype_score},...
                     'phenotype_label', {phenotype_label},...
                     'column_group', {col_gpv});
end

function [args, help_flag] = getArgs(varargin)
config = struct('name',...
            {'--ds';...
            '--phenotype_score_field';...
            '--phenotype_label_field';...
            '--column_group';...
            '--ps_sens_th';...
            '--ps_insens_th';...
            '--fr_insens_th';...
            },...
    'default', {'';...
                '';...
                '';...
                '';...
                80;...
                80;...
                0.25},...
    'help', {'Connectivity matrix (PS scores)';...
            'Column metadata field containing Phenotype scores';...
            'Column metadata field containing binarized Phenotype labels 1=sensitive 0=insensitive class';...
            'Grouping variable for columns';...
            'Connectivity within sensitive class';...
            'Connectivity within insensitive class';...
            'Fraction of high connections in insensitive class'});
opt = struct('prog', mfilename, 'desc', 'Compute differential connectivity');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
end