function out = runMatchedGutcV2(varargin)
% runMatchedGutcV2 : Apply matched mode GUTC to raw connectivity scores.

[args, help_flag] = get_args(varargin{:});

import mortar.util.Message

if ~help_flag  
    out = struct('args', args,...
             'cs_sig', '',...
             'ns_sig', '',...
             'ps_sig', '',...
             'ns_rpt', '',...
             'ns_pert_cell', '',...
             'ps_pert_cell', '',...
             'ns_pert_summary', '',...
             'ps_pert_summary', '',...
             'ns_pcl_cell', '',...
             'ps_pcl_cell', '',...
             'ns_pcl_summary', '',...
             'ps_pcl_summary', '',...
             'query_info', '');
         
    %% Touchstone filepaths
    ts_rpt = mortar.compute.Gutc.getTouchStoneFiles(args.bkg_path, args.pcl_set);
    
    %% normalize raw scores using touchstone signature distributions
    out.cs_sig = parse_gctx(args.cs);
    if ~isempty(args.col_meta)
        out.cs_sig = annotate_ds(out.cs_sig, args.col_meta, 'dim', 'column');
    end
    % signature annotations
    annot_sig = parse_record(ts_rpt.annot_sig, 'detect_numeric', ...
                            false);
    % touchstone signatures
%     sig_ts = parse_grp(ts_rpt.ts_sig);
    if isfield(annot_sig, 'is_touchstone')
        is_ts = strcmp({annot_sig.is_touchstone}, '1');
        sig_ts = {annot_sig(is_ts).sig_id}';
    else
        error(sprintf('%s:MissingAnnotationError', mfilename), 'Missing field: is_touchstone');
    end
    
    % Keep sigs from main pert types
    keep_pt = ismember({annot_sig.pert_type}, {'trt_cp', ...
                        'trt_sh.cgs', 'trt_oe', 'ctl_vehicle', 'ctl_vector'});
    annot_sig = annot_sig(keep_pt);
    sig_id = {annot_sig.sig_id}';
    % restrict TS to the annotation space
    sig_ts = intersect(sig_ts, sig_id);
    % restrict results to annotation space
    out.cs_sig = ds_slice(out.cs_sig, 'rid', sig_id);
    out.cs_sig = annotate_ds(out.cs_sig, annot_sig, 'dim', 'row');

    Message.debug(args.verbose, '# Normalizing query results relative to touchstone');
    [out.ns_sig, out.ns_rpt] = mortar.compute.Gutc.normalizeQueryRef(out.cs_sig, sig_ts);

    %% pert_cell : Aggregate NS rows by pert_id and cell_id
    Message.debug(args.verbose, '# Aggregating rows by pert_id, cell_id');
    out.ns_pert_cell = mortar.compute.Gutc.aggregateQuery(out.ns_sig, [],...
                                  {'pert_id', 'cell_id'}, 'column',...
                                  args.aggregate_method, args.aggregate_param);
    out.ns_pert_cell = ds_delete_meta(out.ns_pert_cell, 'row', setdiff(out.ns_pert_cell.rhd,...
                        {'pert_id', 'pert_iname', 'cell_id', 'pert_type'}));                                     
    ns2ps_pert_cell = parse_gctx(ts_rpt.ns2ps_pert_cell);

    %% Apply matching on normalized scores
    Message.debug(args.verbose,...
                   '# Matching queries to rows by %s for each %s',...
                   args.match_field, args.match_rid_field);
    tmp = mortar.compute.Gutc.matchQuery(out.ns_pert_cell, 1, args.match_field, args.match_rid_field);
    % query metadata with match_group field
    [out.ns_pert_cell, ~, out.query_info] = ...
        mortar.compute.Gutc.castDSToLong(tmp, args.match_field, args.match_cid_field);
    % rename match_group to query_id to match gutc index.txt file
    out.query_info = mvfield(out.query_info, 'match_group', 'query_id');

    % Compute percentiles
    [out.ps_pert_cell, out.ns_pert_cell] = ...
        mortar.compute.Gutc.scoreToPercentile(out.ns_pert_cell,...
                                              ns2ps_pert_cell, 'column');
    %% pert_summary: Aggregate NS rows by pert_id
    Message.debug(args.verbose, '# Aggregating rows by pert_id');
    out.ns_pert_summary = mortar.compute.Gutc.aggregateQuery(out.ns_pert_cell,...
                                [], {'pert_id'}, 'column',...
                                args.aggregate_method, args.aggregate_param);
    out.ns_pert_summary = ds_delete_meta(out.ns_pert_summary, 'row', setdiff(out.ns_pert_cell.rhd,...
                        {'pert_id', 'pert_iname', 'pert_type'}));                                             
    ns2ps_pert_summary = parse_gctx(ts_rpt.ns2ps_pert_summary);
    [out.ps_pert_summary, out.ns_pert_summary] = ...
        mortar.compute.Gutc.scoreToPercentile(out.ns_pert_summary,...
                                              ns2ps_pert_summary, 'column'); 
                        
    %% pcl_cell : 
    Message.debug(args.verbose, '# Computing PCL results per cell line');
    out.ns_pcl_cell = mortar.compute.Gutc.aggregateSetByCell(...
                        out.ns_pert_cell,...
                        [],...
                        ts_rpt.pcl_set,...
                        'column',...
                        'pert_id',...
                        args.aggregate_method,...
                        args.aggregate_param);
    ns2ps_pcl_cell = parse_gctx(ts_rpt.ns2ps_pcl_cell);
    % Compute percentiles
    [out.ps_pcl_cell, out.ns_pcl_cell] = mortar.compute.Gutc.scoreToPercentile(...
        out.ns_pcl_cell,...
        ns2ps_pcl_cell, 'column');
                    
    %% pcl_summary :
    Message.debug(args.verbose, '# Computing summarized PCL results');
    out.ns_pcl_summary = mortar.compute.Gutc.aggregateSet(...
                        out.ns_pert_summary,...
                        [],...
                        ts_rpt.pcl_set,...
                        'column',...
                        'pert_id',...
                        args.aggregate_method,...
                        args.aggregate_param);
    ns2ps_pcl_summary = parse_gctx(ts_rpt.ns2ps_pcl_summary);
    % Compute percentiles
    [out.ps_pcl_summary, out.ns_pcl_summary] = ...
        mortar.compute.Gutc.scoreToPercentile(...
            out.ns_pcl_summary,...
            ns2ps_pcl_summary, 'column');
end
end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Compute GUTC in unmatched mode', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

% sanity checks
% assert((isequal(args.es_tail, 'both') && ~isempty(args.uptag) && ~isempty(args.dntag)) ||...
%         (isequal(args.es_tail, 'up') && ~isempty(args.uptag)) ||...
%         (isequal(args.es_tail, 'down') && ~isempty(args.dntag)),...
%         'Invalid query specified');

end
