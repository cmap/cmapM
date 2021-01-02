function [ofname, status, result] = mkheatmap(dsfile, outfile, varargin)
% mkheatmap Wrapper for heatmap

% Heatmap script
hm_script = '/cmap/bin/heatmap';
pnames = {'format', 'cdesc', 'rdesc', ...
    'iszscore', 'debug', 'cluster_row',...
    'cluster_col', 'cluster_distance', 'cluster_linkage'};
dflts = {'png', {'id'}, {'id'}, ...
    false, true, false, ...
    false, 'correlation', 'complete'};

distance_dict = containers.Map({'city block', 'euclidean', 'kendall', 'correlation', 'spearman'}, (0:4));
linkage_dict = containers.Map({'average', 'complete', 'single'}, (0:2));
args = parse_args(pnames, dflts, varargin{:});
ofname = sprintf('%s.%s', outfile, args.format);

% Heatmap options
cdesc = print_dlm_line(args.cdesc, 'dlm', ' ');
rdesc = print_dlm_line(args.rdesc, 'dlm', ' ');
optflag = sprintf('-f %s', args.format);
if args.iszscore
    optflag = sprintf('%s --zscores', optflag);
end

% Clustergram options
distance_id = distance_dict(args.cluster_distance);
linkage_id = linkage_dict(args.cluster_linkage);
if args.cluster_col
    optflag = sprintf('%s --clustc --cdist %d --linkage %d', optflag, distance_id, linkage_id);
end
if args.cluster_row
    optflag = sprintf('%s --clustr --rdist %d --linkage %d', optflag, distance_id, linkage_id);
end

flags = sprintf('--cdesc %s --rdesc %s %s', cdesc, rdesc, optflag);

% run it
runstring = sprintf('%s -i %s -o %s %s', hm_script, dsfile, outfile, flags);
dbg (args.debug, 'Saving heatmap to: %s...', ofname)
dbg (args.debug, '%s', runstring)
[status, result] = system(runstring, '-echo');
dbg (args.debug, 'done.')

end