function ts_rpt = getTouchStoneFiles(ts_path, pcl_set)
% GetTouchstoneFiles Get paths to touchstone related files

ts_rpt = struct('annot_sig', 'annot/siginfo_n*.txt',...
                'annot_pert_cell', 'annot/pert_cell_n*.txt',...
                'annot_pert_summary', 'annot/pert_summary_n*.txt',...
                'sig_id_matched', 'annot/sig_id_matched_n*.grp',...
                'pcl_set', '',...
                'ns2ps_pert_cell', 'pert_cell/ns2ps.gctx',...
                'ns2ps_pert_summary', 'pert_summary/ns2ps.gctx',...
                'ns2ps_pcl_cell', 'pcl_cell/ns2ps.gctx',...
                'ns2ps_pcl_summary', 'pcl_summary/ns2ps.gctx');
            
assert(mortar.util.File.isfile(ts_path, 'dir'),...
    'Touchstone folder not found: %s', ts_path);
fn = fieldnames(ts_rpt);
nf = length(fn);
for ii=1:nf
    pat = ts_rpt.(fn{ii});
    if ~isempty(pat)
        pat = fullfile(ts_path, pat);
        [~, fp] = find_file(pat);
        nfp = numel(fp);
        if ~isempty(fp) && isequal(nfp, 1)
            ts_rpt.(fn{ii}) = fp{1};
        else
            if nfp>1
                error('Multiple touchstone files matching %s found', pat)
            else
                error('Required touchstone file not found matching %s', pat)
            end
        end
    end
end

%% PCL definition
assert(mortar.util.File.isfile(pcl_set, 'file'),...
    'PCL file not found: %s', pcl_set);
ts_rpt.pcl_set = pcl_set;
