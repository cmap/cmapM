function res = runAnalysis(varargin)
import mortar.util.Message

[help_flag, args] =  getArgs(varargin{:});
if ~help_flag
    import mortar.compute.Connectivity
    
    t0 = tic;
    
    Message.log(args.verbose, '# Computing enrichment');
    res = Connectivity.runCmapQuery(varargin{:});

    Message.log(args.verbose, '# Contructing permuted sets');
    annot = parse_gctx(args.rank, 'annot_only', true);
    up = parse_geneset(args.up);
    [pset, sz_gp] = getPermutedSet(up, annot.rid, args.nperm);
    
    Message.log(args.verbose, '# Computing enrichment of permuted sets');
    perm_res = mortar.compute.Connectivity.runCmapQuery(varargin{:}, '--up', pset);
    
    
 
    
    Message.log(args.verbose, '# END [%2.1f s].', toc(t0));

end

end

function ncs = normalizeScore(cs, perm_cs, sets)
end

function [pset, sz_gp] = getPermutedSet(sets, setspace, n)
   [set_sz, set_idx] = getcls([sets.len]);
   nsz = length(set_sz);
   ns = length(setspace);
   phead = cell(nsz*n, 1);
   plen = zeros(nsz*n, 1);
   pdesc = cell(nsz*n, 1);
   pentry = cell(nsz*n, 1);
   for ii=1:nsz
       for jj=1:n
           idx = (ii-1)*n + jj;
           phead{idx} = sprintf('RNDSET_n%d_i%d', set_sz(ii), jj);
           pdesc{idx} = sprintf('%d', set_sz(ii));
           plen(idx) = set_sz(ii);
           pentry{idx} = setspace(randsample(ns, set_sz(ii)));
       end
   end
   
   pset = struct('head', phead,...
                 'desc', pdesc,...
                 'len', num2cell(plen),...
                 'entry', pentry);
   sz_gp = set_sz(set_idx);
end

function [help_flag, args] = getArgs(varargin)
%%% Parse arguments
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Assess set enrichment', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

end