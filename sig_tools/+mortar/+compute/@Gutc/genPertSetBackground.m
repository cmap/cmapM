function bkg = genPertSetBackground(varargin)

[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    bkg = struct('ns', '',...
                 'ns2ps', '',....
                 'stats', '');
    % checks args
    checkArgs(args);
    
    % compute pert set scores
    bkg.ns = mortar.compute.Gutc.aggregateSetByCell(args.ds,...
                                             args.meta,...
                                             args.pert_set,...
                                             args.dim);
[dim_str, dim_val] = get_dim2d(args.dim);
set_dim = 3-dim_val;

    % assess background
    [bkg.ns2ps, bkg.stats] = mortar.compute.Gutc.scoreToPercentileTransform(...
                                bkg.ns,...
                                set_dim,...
                                args.min_val,...
                                args.max_val,...
                                args.nbin,...
                                'method', args.ps_method);
                                         
else
    bkg = [];
end

end

function checkArgs(args)
assert(~isempty(args.ds), 'Dataset not specified');
assert(~isempty(args.pert_set), 'Pert Set not specified');
end

function [args, help_flag] = getArgs(varargin)
scriptName = mfilename;        
className = mfilename('class'); 
fullName = sprintf('%s.%s', className, scriptName);
configFile = mortar.util.File.getArgPath(scriptName, className);
opt = struct('prog', fullName, 'desc', '');
[args, help_flag] = mortar.common.ArgParse.getArgs(configFile, opt, varargin{:});
end
