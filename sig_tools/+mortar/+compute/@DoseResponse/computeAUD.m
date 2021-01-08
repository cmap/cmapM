function auc_ds = computeAUD(varargin)
% computeAUD Calculate area under dose data for a dataset
% AUC_DS = computeAUD(ZS, varargin) ZS_DS is an annotated dataset (GCT file or
% structure) of z-scores of perturbagen treatment across multiple
% treatment concentrations (e.g. Level-5 viability signatures).
% The function minimally expects the following column meta data fields to exist {'pert_id', 'pert_dose', 'pert_idose', 'pert_iname'}
% where 'pert_dose' is the micromolar treatment concentration. The area
% under log10 dose data is computed per feature (row) for each unique pert_id in the dataset.
%
% Type computeAUD('help') for details of arguments
% See also AUC_DOSE

[help_flag, args] = getArgs(varargin{:});

if ~help_flag
    zs = parse_gctx(args.zs);
    % sort all columns by pert_id, dose
    pert_id = ds_get_meta(zs, 'column', 'pert_id');
    pert_dose = ds_get_meta(zs, 'column', 'pert_dose');
    [~, srt_ord] = sorton([pert_id, num2cell(pert_dose)], [1,2], 1, {'ascend', 'ascend'});
    zs = ds_slice(zs, 'cidx', srt_ord);
    
    %% AUC per unique pert_id
    pert_id = ds_get_meta(zs, 'column', 'pert_id');
    pert_dose = ds_get_meta(zs, 'column', 'pert_dose');
    pert_idose = ds_get_meta(zs, 'column', 'pert_idose');
    pert_iname = ds_get_meta(zs, 'column', 'pert_iname');
    is_valid_dose = pert_dose>0;
    
    [cn, nl] = getcls(pert_id);
    nc = length(cn);
    [~, uord] = unique(nl, 'stable');
    cm = gctmeta(zs);
    row_meta = gctmeta(zs, 'row');
    column_meta = keepfield(cm(uord),...
        intersect({'pert_id', 'pert_iname', 'pert_type', 'moa', 'target_name'},...
        fieldnames(cm), 'stable'));
    [column_meta.cid] = column_meta.pert_id;
    
    nrow = size(zs.mat, 1);
    auc_mat = nan(nrow, nc);
    % number of unique doses
    num_dose = zeros(nrow, 1);
    for ii=1:nc
        this_cp = nl == ii & is_valid_dose;
        num_dose(ii) = length(unique(pert_idose(this_cp)));
        this_iname = pert_iname(this_cp);
        
        if num_dose(ii) > 2
            %dbg(1, '%d/%d %s %d doses', ii, nc, cn{ii}, num_dose(ii));
            this_dose = pert_dose(this_cp);
            this_zs = ds_slice(zs, 'cidx', this_cp);
            auc_mat(:, ii) = auc_dose(log10(this_dose),...
                this_zs.mat', args.rectify_sign, args.do_norm, args.norm_scale);
        else
            dbg(1, '%d/%d %s (%s) Only %d unique doses found, skipping',...
                ii, nc, cn{ii}, num_dose(ii))
        end
    end
    %%
    auc_ds = mkgctstruct(auc_mat, 'rid', zs.rid, 'cid', cn);
    auc_ds = annotate_ds(auc_ds, column_meta, 'keyfield', 'cid');
    auc_ds = annotate_ds(auc_ds, row_meta, 'dim', 'row');
    auc_ds = ds_delete_missing(auc_ds);
end
end

function [help_flag, args] = getArgs(varargin)
config = struct('name', {'zs';'--rectify_sign';'--do_norm';'--norm_scale'},...
    'default', {''; -1; true; 1},...
    'help', {'Z-Score dataset';...
             'The values contributing to the area are determined by RECTIFY_SIGN. If RECTIFY_SIGN = 0 then all ZS values are used when computing the area. If RECTIFY_SIGN < 0 all positive ZS values are set to 0 and the area is computed using the negative values. If RECTIFY_SIGN > 0 only positive ZS values are used after setting negative values to 0.';
             'If true, the computed AUD is normalized by SCALE * (max(LOGD)-min(LOGD))';...
             'Scale factor used for normalization'});
opt = struct('prog', mfilename, 'desc', 'Calculate area under dose data for a dataset');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

end