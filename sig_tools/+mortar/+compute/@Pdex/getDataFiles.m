function rpt = getDataFiles(pdex_path)
% GetDataFiles Get files related to PDEX analysis

rpt = struct('annot_col', 'build/col_meta.txt',...
                'annot_row', 'build/row_meta.txt',...
                'build_score', 'build/pdex_cmap_ps_n*.gctx',...
                'build_rank', 'build/pdex_cmap_rank_n*.gctx',...
                'ns2ps_lookup', '');
            
assert(mortar.util.File.isfile(pdex_path, 'dir'),...
    'PDEX folder not found: %s', pdex_path);
fn = fieldnames(rpt);
nf = length(fn);

bkg_path = fullfile(pdex_path, 'bkg');
for ii=1:nf
    pat = rpt.(fn{ii});
    if ~isempty(pat)
        pat = fullfile(pdex_path, pat);
        [~, fp] = find_file(pat);
        nfp = numel(fp);
        if ~isempty(fp) && isequal(nfp, 1)
            rpt.(fn{ii}) = fp{1};
        else
            if nfp>1
                disp(fp)
                error('Multiple PDEX files matching %s found', pat)
            else
                error('Required PDEX file not found matching %s', pat)
            end
        end
    end
end


assert(mortar.util.File.isfile(bkg_path, 'dir'),...
    'Background folder not found: %s', bkg_path);
[fname, fpath] = find_file(fullfile(bkg_path, 'query_*'));
nfolder = length(fpath);
set_sizes = zeros(nfolder, 1);
bkg_file = cell(nfolder, 1);
for ii=1:nfolder
    this_set_size = str2double(strrep(fname{ii}, 'query_', ''));
    ns2ps_file = fullfile(fpath{ii},'norm2ps.gctx');
    assert(mortar.util.File.isfile(ns2ps_file, 'file'),...
    'NS2PS file not found: %s', ns2ps_file);
    set_sizes(ii) = this_set_size;
    bkg_file{ii} = ns2ps_file;
end

rpt.ns2ps_lookup = mortar.containers.Dict(set_sizes, bkg_file);



