function [ps, agg_ns] = getPertSetPercentile(varargin)
% getPertSetPercentile
[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    % checks args
    %checkArgs(args);
    aggregate_method = 'maxq';
    aggregate_param = struct('q_low', 33, 'q_high', 67);
    ns2ps = getBackground(args.bkg_path);
    agg_ns = mortar.compute.Gutc.aggregateSetByCell(args.ds, args.meta, args.pert_set, args.dim,...
                               args.match_field, aggregate_method,...
                               aggregate_param);    
    ps = mortar.compute.Gutc.scoreToPercentile(agg_ns, ns2ps, args.dim);                                         
else
    agg_ns = [];
    ps = [];
end

end

function ns2ps = getBackground(bkg_path)
[~, fp] = find_file(fullfile(bkg_path, 'ns2ps*.gct*'));
assert(~isempty(fp),...
    'background file ns2ps.gct* not found at %s',...
    bkg_path);
disp(fp);
assert(isequal(numel(fp), 1), 'Multiple background files found, see above for a list');
ns2ps = parse_gctx(fp{1});
end

function [args, help_flag] = getArgs(varargin)
scriptName = mfilename;        
className = mfilename('class'); 
fullName = sprintf('%s.%s', className, scriptName);
configFile = mortar.util.File.getArgPath(scriptName, className);
opt = struct('prog', fullName, 'desc', '');
[args, help_flag] = mortar.common.ArgParse.getArgs(configFile, opt, varargin{:});
end
