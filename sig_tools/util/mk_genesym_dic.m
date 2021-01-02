function mk_genesym_dic(out, varargin)
% mk_genesym_dic Generate dictionaries mapping gene symbols to probe sets
% mk_genesym_dic(out, varargin)
% Generates a structure with fields "all", "eps", and "deltap"
% These correspond to, respectively:
%   1.  Each gene symbol is mapped to all probes
%   2.  Each epsilon landmark gene is mapped to its lm probe; all non-landmarks
%       are mapped to all probes
%   3.  Each deltaprime landmark gene is mapped to its lm probe; all non-landmarks
%       are mapped to all probes
% Users shouldn't have to access the structure directly; just use ps2genesym_fast
% mk_genesym_dic(varargin)
% Inputs:
%   out: The output file for the matlab data
%   chipfile: The chip file from which to construct the dictionary
%       Default: /cmap/data/vdb/chip/affx.chip
%   lm_genes: The file with the list of landmark genes
%       Default: /cmap/data/vdb/spaces/lm_symbols.gmx
%   lm_probes: The file with the list of landmark probe sets
%       Default: '/cmap/data/vdb/spaces/lm_probes.gmx'


% get arguments
pnames = {'chipfile', 'lm_genes', 'lm_probes'};
dflts = {   '/cmap/data/vdb/chip/affx.chip', ...
            '/cmap/data/vdb/spaces/lm_symbols.gmx', ...
            '/cmap/data/vdb/spaces/lm_probes.gmx'};
args = parse_args(pnames, dflts, varargin{:});

% preallocate the structure
D = struct( 'all', containers.Map, ...
            'eps', containers.Map, ...
            'deltap', containers.Map);
        
% grab the reference data
chip = dataset('File', args.chipfile, 'Delimiter', '\t');
lm_probes = parse_gmx(args.lm_probes);
lm_genes = parse_gmx(args.lm_genes);
genes = unique(chip.pr_gene_symbol);

eps_lm_probes = lm_probes(strcmp({lm_probes.head}, 'eps')).entry;
deltap_lm_probes = lm_probes(strcmp({lm_probes.head}, 'deltap')).entry;
eps_lm_genes = lm_genes(strcmp({lm_genes.head}, 'eps')).entry;
deltap_lm_genes = lm_genes(strcmp({lm_genes.head}, 'deltap')).entry;

% loop over the genes and fill them in
ngenes = length(genes);
cnt = 0;
for ii = 1:length(genes)
    cnt = cnt + 1;
    if ~mod(cnt, 1000)
        fprintf('%d of %d genes mapped\n', cnt, ngenes)
    end
    g = genes{ii};
    if strcmp(g, '') || ~isempty(regexp(g, '^-666', 'Once')) || ...
            ~isempty(regexp(g, '^///', 'Once'))
        continue
    end
    idx = strcmp(g, chip.pr_gene_symbol);
    D.all(g) = chip.pr_id(idx);
    if ismember(g, eps_lm_genes)
        D.eps(g) = intersect(D.all(g), eps_lm_probes);
    else
        D.eps(g) = D.all(g);
    end
    if ismember(g, deltap_lm_genes)
        D.deltap(g) = intersect(D.all(g), deltap_lm_probes);
    else
        D.deltap(g) = D.all(g);
    end
end

% save the dictionary to file
save(out, 'D')
        
        
        
        
        
