function runAnalysis_(obj, varargin)
args = obj.getArgs;
out_path = obj.getWkdir;
obj.res_ = main(args, out_path);
end

function res = main(args, out_path)
% Main function
% ADD CORE CODE BELOW
res = struct('args', args);

if res.args.use_gctx
    gctwriter = @mkgctx;
else
    gctwriter = @mkgct;
end

out_file = fullfile(out_path, 'rank.gctx');
if ~isempty(args.outfile)
    out_file = fullfile(out_path, args.outfile);
end

switch(args.read_mode)
    case 'full'
        ds = parse_gctx(args.ds);
        ds_rank = get_ranks(ds, args);
        gctwriter(out_file, ds_rank);
    case 'iterative'
        %ds_annot = parse_gctx(args.ds, 'id_only', true);
        dim_str = get_dim2d(args.dim);       
        [ds, cur] = ds_iter(args.ds, args.block_size', '', 'dim', dim_str);
        while ~isempty(ds)
            ds_rank = get_ranks(ds, args);
            ds_append(ds_rank, out_file, 'block_size', args.block_size);
            [ds, cur] = ds_iter(args.ds, args.block_size', cur, 'dim', dim_str);
        end
    otherwise
        error('Unknown read mode:%s', args.read_mode)
end

end

function ds_rank = get_ranks(ds, args)
ds_rank = score2rank(ds, ...
    'direc', args.sort_order, ...
    'dim', args.dim, ...
    'ignore_nan', args.ignore_nan, ...
    'as_fraction', args.as_fraction, ...
    'as_percentile', args.as_percentile, ...
    'fixties', args.fix_ties);
end