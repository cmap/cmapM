function ds_append(srcfile, tgtfile, varargin)
% Append to a GCTX dataset
% DS_APPEND(SRC, TGT)
% DS_APPEND(SRC, TGT, 'param1, val1, 'param2', val2...)
% 'block_size' : 

pnames = {'block_size'};
dflts = {10000};
args = parse_args(pnames, dflts, varargin{:});

assert(isstruct(srcfile) || isfileexist(srcfile));
% assert(isfileexist(tgtfile));

[src, cur] = ds_iter(srcfile, args.block_size, '', varargin{:});
while ~isempty(src)
    if ~isfileexist(tgtfile)
        mkgctx(tgtfile, src, 'appenddim', false);
    else
        mkgctx(tgtfile, src, 'insert', true, 'update', true, 'appenddim', false);
    end
    [src, cur] = ds_iter(srcfile, args.block_size, cur, varargin{:});
end
  
end
