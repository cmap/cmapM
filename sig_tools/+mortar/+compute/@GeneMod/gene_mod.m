function gene_mod(varargin)
% given a gene
% extract a row from the modz matrix
% append annotations
% create a pert x 
% apply sig filters

args = getargs(varargin{:});

out_folder = mktoolfolder(args.out, mfilename);
print_args(mfilename, fullfile(out_folder, sprintf('%s_params.txt', mfilename)), args);

modz = parse_gctx(args.zs, 'rid', args.rid);
modz = ds_slice(modz, 'cid', args.sig_space);
% transpose the matrix
modz = transpose_gct(modz);

% add annotations
modz = annotate_ds(modz, args.annot, 'keyfield', 'sig_id', 'dim', 'row');
modz = annotate_ds(modz, gene_info(modz.cid), 'keyfield', 'pr_id', 'dim', 'column');

% cid = unique(ds_get_meta(modz, 'row', 'cell_id'));
% 
[gpvar, gp, gpidx, gpfn, gpsz] = get_groupvar(modz.rdesc, modz.rhd, {'pert_id', 'cell_id'});
[rid, val] = grpstats(modz.mat, gpvar, {'gname', args.aggregate_fun});
%%
pert_id = ds_get_meta(modz, 'row', 'pert_id');
pert_iname = ds_get_meta(modz, 'row', 'pert_iname');
pert_type = ds_get_meta(modz, 'row', 'pert_type');

tok = tokenize(rid, ':');
rid_pert = cellfun(@(x) x{1}, tok, 'uniformoutput', false);
rid_cell = cellfun(@(x) x{2}, tok,  'uniformoutput', false);

% [~, ~, ridx] = intersect(rid_pert, pert_id, 'stable');
[~, ridx]=map_ord(pert_id, rid_pert);
assert(isequal(pert_id(ridx), rid_pert));
rid_iname = pert_iname(ridx);
rid_type = pert_type(ridx);

%% generate pert_id x cell_id
[pert_gp, pert_nl] = getcls(rid_pert);
[cell_gp, cell_nl] = getcls(rid_cell);

[~, uidx] = unique(pert_nl);

npert = length(pert_gp);
ncell = length(cell_gp);

zs = nan(npert, ncell);
for ii=1:npert
    idx = pert_nl==ii;
    cidx = cell_nl(idx);
    zs(ii, cidx) = val(idx, 1);    
end

gm = mkgctstruct(zs, 'rid', pert_gp, 'cid', cell_gp);
gm = ds_add_meta(gm, 'row', {'pert_iname', 'pert_type'}, [rid_iname(uidx), rid_type(uidx)]);
gm = sort_matrix(gm);
topn = clip(args.topn, 1, length(gm.rid));
gm_down = get_top(gm, topn, true);
gm_up = get_top(gm, topn, false);

% save data
mkgctx(fullfile(out_folder, 'genemod.gctx'), gm);
mkgctx(fullfile(out_folder, 'genemod_dn.gctx'), gm_down);
mkgctx(fullfile(out_folder, 'genemod_up.gctx'), gm_up);

% make heatmaps
gene_sym = ds_get_meta(modz, 'column', 'pr_gene_symbol');
plot_heatmap(gm_down, sprintf('%s DOWN modulators', gene_sym{1}), 'genemod_dn');
plot_heatmap(gm_up, sprintf('%s UP modulators', gene_sym{1}), 'genemod_up');
savefigures('out', out_folder, 'mkdir', false, 'closefig', true);

end

function ds = sort_matrix(ds)
% sort rows and columns gene mod matrix by degree of modulation

% number of non-nan elements per row
row_nnan = sum(~isnan(ds.mat), 2);
col_nnan = sum(~isnan(ds.mat), 1);

% sort rows based on the 25 percentile
row_q25 = q25(ds.mat, 2);
% ignore rows with < 3 non-nan values
row_q25(row_nnan < 3) = 0;
[~, ridx] = sort(row_q25, 'ascend');

% sort columns the same way
% col_q25 = q25(ds.mat, 1);
% col_q25(col_nnan < 3) = 0;
[~, cidx] = sort(col_nnan, 'descend');

ds = ds_slice(ds, 'ridx', ridx, 'cidx', cidx);
end

function x = get_top(gm, n, is_top)
nr = size(gm.mat, 1);
if is_top
    x = ds_slice(gm, 'ridx', 1:clip(n, 1, nr));
else
    x = ds_slice(gm, 'ridx', clip(nr-(0:n-1), 1, nr));
end
x = ds_delete_missing(x);
x = sort_matrix(x);
end

function plot_heatmap(x, title_str, name_str)
%%

myfigure(false)
imagescnan(x.mat, zsmap, get_color('grey'), [-10, 10])
axis square
if length(x.cid) < 50
    set(gca, 'xtick', 1:length(x.cid), 'xticklabel', texify(x.cid));
    th = rotateticklabel(gca, 45);
    set(th, 'fontsize', 8, 'fontweight', 'bold')
end
if length(x.rid)<50
    row_label = ds_get_meta(x, 'row', 'pert_iname');
    set(gca, 'ytick', 1:length(x.rid), 'yticklabel', texify(row_label),...
        'fontsize', 10, 'fontweight', 'bold');    
end

title(title_str);
xlabel('Cell line')
ylabel('Perturbagen')
grid off
namefig(name_str);

end


function args = getargs(varargin)

pnames = {'rid',...
          '--zs',...
          '--annot',...
          '--sig_space',...
          '--aggregate_fun',...
          '--out',...
          '--topn',...
         };

dflts = {'',...
         '/cmap/data/build/a2y13q1/modzs.gctx',...
         '/cmap/data/build/a2y13q1/sig.info',...
         '',...
         'min',...
         pwd,...
         30,...
        };
    
desc = {'Probeset id',...
        'Moderated Zscore matrix',...
        'Annotation table for the zscore matrix',...
        'Signature space to restrict the analysis to',...        
        'Aggregation function to summarize values from multiple signatures',...
        'Output folder',...
        'Number of top hits to select',...
        };
    
p = mortar.common.ArgParse(mfilename);
p.add(struct('name', pnames, 'default', dflts, 'help', desc));
args = p.parse(varargin{:});

end
