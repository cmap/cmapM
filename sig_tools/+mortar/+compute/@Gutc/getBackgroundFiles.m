function ts_rpt = getBackgroundFiles(bkg_path)
% getBackgroundFiles Get paths files used to compute GUTC background
%   R = getBackgroundFiles(BKG_PATH)

ts_rpt = struct('annot_sig', 'annot/siginfo.txt',...
                'annot_pert_cell', 'annot/pert_cell_n*.txt',...
                'annot_pert_summary', 'annot/pert_summary_n*.txt',...
                'pcl_set', 'annot/pcl_n*.gmt',...
                'ns2ps_sig', 'sig/ns2ps*.gctx',...
                'ns2ps_pert_cell', 'pert_cell/ns2ps*.gctx',...
                'ns2ps_pert_summary', 'pert_summary/ns2ps*.gctx',...
                'ns2ps_pcl_cell', 'pcl_cell/ns2ps*.gctx',...
                'ns2ps_pcl_summary', 'pcl_summary/ns2ps*.gctx');
            
assert(mortar.util.File.isfile(bkg_path, 'dir'),...
    'Background folder not found: %s', bkg_path);
fn = fieldnames(ts_rpt);
nf = length(fn);
for ii=1:nf
    pat = ts_rpt.(fn{ii});
    if ~isempty(pat)
        pat = fullfile(bkg_path, pat);
        [~, fp] = find_file(pat);
        nfp = numel(fp);
        if ~isempty(fp) && isequal(nfp, 1)
            ts_rpt.(fn{ii}) = fp{1};
        else
            if nfp>1
                error('Multiple files matching %s found', pat)
            else
                warning('Background file not found matching %s, skipping', pat)
                ts_rpt.(fn{ii}) = '';
            end
        end
    end
end
% %% PCL definition
% assert(mortar.util.File.isfile(pcl_set, 'file'),...
%     'PCL file not found: %s', pcl_set);
% ts_rpt.pcl_set = pcl_set;

end
