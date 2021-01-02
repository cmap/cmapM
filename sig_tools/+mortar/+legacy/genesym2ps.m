function [ps, gp, gpidx] = genesym2ps(gs, varargin)
% GENESYM2PS Convert gene symbols to Affymetrix probeset ids.
%   PS = GENESYM2PS(GS)
%   PS = GENESYM2PS(GS, param, value,...), Specify optional parameters:
%
%   'chip': string, Affymetrix chip name. Default is HG_U133A. Valid
%           options are:{HG_U133A, HG_U133AAOFAV2, HG_U133A_2, HG_U133B,
%           HG_U133_Plus_2}
%   'ann_path': string, Path to annotation chip files
%   'unwrap': boolean, unwrap cell array if there are multiple
%             probesets per gene.
%   'dlm': string, delimiter for seprating multiple probesets per gene.
%          Default is ' /// '

pnames = {'chip', 'ann_path', 'dlm', 'unwrap', 'ignore_missing'};
dflts = {'affx', mapdir('/cmap/data/vdb/chip'), ' /// ', false, false};
args = parse_args(pnames, dflts, varargin{:});

annfile = fullfile(args.ann_path, sprintf('%s.chip', lower(args.chip)));
lutfile = fullfile(args.ann_path, sprintf('%s.g2p', lower(args.chip)));
if ischar(gs)
    gs = {gs};
else
    gs = gs(:);
end
ngs = length(gs);

if isfileexist(lutfile)
    lut = parse_sin(lutfile);
%     g2p = containers.Map(lut.pr_gene_symbol, lut.pr_id);
    g2p = list2dict(lut.pr_gene_symbol);
    gidx = zeros(ngs, 1);
    blank = {''};
    ps = blank(ones(ngs, 1));    
    gexists = g2p.isKey(gs);
    if all(gexists) || args.ignore_missing
        gidx(gexists) = cell2mat(g2p.values(gs(gexists)));
        ps(gexists) = lut.pr_id(gidx(gexists));
        gpidx = 1:ngs;
        gp = gs;
        if args.unwrap
            ismulti = ~cellfun(@isempty, regexp(ps, ' /// '));
            newlen = length(ismulti)+sum(ismulti);
            newps = cell(newlen, 1);
            gpidx = zeros(newlen, 1);
            ctr = 1;
            for ii=1:length(ps)
                if ismulti(ii)
                    tok = tokenize(ps{ii}, ' /// ');
                    newps(ctr+(0:length(tok)-1)) = tok;
                    gpidx(ctr+(0:length(tok)-1)) = ii;
                    ctr = ctr + length(tok);
                else
                    newps(ctr) = ps(ii);
                    gpidx(ctr) = ii;
                    ctr = ctr + 1;
                end
            end
            keep = ~strcmp('',newps);
            ps = newps(keep);
            gpidx = gpidx(keep);
            gp = gs(gpidx);
        end
    else
        disp(setdiff(gs, g2p.keys))
        error('Some symbols not found')
    end
    
elseif isfileexist(annfile)
    ann = parse_sin(annfile);
    % generate single list of probesets length(ps) > = length(gs)
    if args.unwrap
      ps = {};
      for ii=1:length(gs)
          pidx = find(~cellfun(@isempty,regexpi(ann.pr_gene_symbol, sprintf('^\\W*\\<%s\\>\\W*$', gs{ii}))));
          %pidx = strmatch(gs{ii}, ann.Gene_Symbol, 'exact');
          ps = [ps; ann.pr_id(pidx)];
      end
      % cell list has same length as gs
    else
      ps = cell(length(gs), 1);
      for ii=1:length(gs)
          pidx = find(~cellfun(@isempty,regexpi(ann.pr_gene_symbol, sprintf('^\\W*\\<%s\\>\\W*$', gs{ii}))));
          %pidx = strmatch(gs{ii}, ann.Gene_Symbol, 'exact');
          ps{ii} = print_dlm_line2(sort(ann.pr_id(pidx)), 'dlm', args.dlm);
      end
    end
else
    error('Annotation File not found: %s', annfile);
end


