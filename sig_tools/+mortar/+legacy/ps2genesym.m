function [gs, gd, ezid] = ps2genesym(ps, varargin)

pnames = {'chip', 'annpath', 'desc'};
dflts = {'affx', mapdir(get_l1k_path('chip_path')), false};
arg = parse_args(pnames, dflts, varargin{:});
annfile = fullfile(arg.annpath, sprintf('%s.chip', lower(arg.chip)));

if isfileexist(annfile)
    ann = parse_tbl(annfile);
    if ischar(ps)
        gs = ann.pr_gene_symbol(strcmp(ps, ann.pr_id));
        if arg.desc && ~isempty(gs)
            gs = strcat('gene=',gs,'|desc=',ann.pr_gene_title(strcmp(ps, ann.pr_id)));
        end
    else
      gs = cell(length(ps), 1);
      gd = gs;
      ezid = gs;
      gs(:) = {''};
      gd(:) = {''};
      ezid(:) = {''};
        [cmn, ia, ib] = map_ord(ann.pr_id, ps);
        gs(ib) = ann.pr_gene_symbol(ia);
        gd(ib) = ann.pr_gene_title(ia);
        ezid(ib) = ann.pr_gene_id(ia);
    end
else
    error('Annotation File not found: %s', annfile);
end


