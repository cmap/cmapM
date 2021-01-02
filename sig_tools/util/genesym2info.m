function info = genesym2info(gs, varargin)
% GENESYM2INFO Convert Affymetrix probeset ids to gene symbols
%   PS = GENESYM2INFO(GS)
%   PS = GENESYM2INFO(GS,...)
% Human chips:
% HG_U133A, HG_U133AAOFAV2, HG_U133A_2, HG_U133B, HG_U133_Plus_2

pnames = {'chip', 'annpath', 'dlm'};
dflts = {'affx', get_l1k_path('chip_path'), ' /// '};
arg = parse_args(pnames, dflts, varargin{:});
annfile = fullfile(arg.annpath, sprintf('%s.chip', arg.chip));

if isfileexist(annfile)
    ann = parse_sin(annfile, 0);
    if ischar(gs)
        gs = {gs};
    end
    
    info = struct('gdesc', '',...
        'entrezid', '',...
        'ps','');
    ngs = length(gs);
    gdesc = cell(ngs, 1);
    entrezid = cell(ngs, 1);
    ps = cell(ngs, 1);
    
    for ii=1:ngs
        idx = find(strcmp(gs{ii}, ann.pr_gene_symbol));
        if ~isempty(idx)
            gdesc{ii} = print_dlm_line2(ann.pr_gene_title(idx(1)), 'dlm', arg.dlm);
            entrezid{ii} = print_dlm_line2(ann.pr_gene_id(idx(1)), 'dlm', arg.dlm);
            ps{ii} = print_dlm_line2(ann.pr_id(idx), 'dlm', arg.dlm);
        end
    end
    info.gdesc = gdesc;
    info.entrezid = entrezid;
    info.ps = ps;
else
    error('Annotation File not found: %s', annfile);
end


