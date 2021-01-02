function x = qnorm(x, varargin)
% QNORM perform quantile normalization.
%   NORMDS = QNORM(DS) Perform quantile normalization across all samples in
%   the dataset DS. DS is a gct structure. Uses the median across the
%   ranked values in the dataset.
%
%   NORMDS = QNORM(DS, 'param', value) specify optional parameters. 
%
%   Valid options are:
%   'use_sketch': boolean, Perform quantile-sketch normalization. 
%       Default is false
%   'target_sketch': GCT file or structure with values to use for sketch
%       normalization.
%   'block_size': integer, perform sketch normalization in blocks of
%       block_size samples. Default is 1000. Note changing block_size will
%       not alter the normalized values, but can speed up processing of
%       large datasets.
pnames = {'use_sketch', 'target_sketch',...
    'block_size', 'verbose'};
dflts = {false, '',...
    1000, true};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(x);
if args.use_sketch
    % quantile-sketch normalization
    sketch = parse_gctx(args.target_sketch);
    ns = size(sketch.mat, 1);
    
    if ~isequal(ns, nr)
        % sketch and dataset have different rows, so interpolate the values
        fprintf('Interpolating the sketch\n')
        sketch.mat = interp1((0:ns-1)/(ns-1), sketch.mat, (0:nr-1)/(nr-1));        
    end
    ng = ceil(nc / args.block_size);
    dbg(args.verbose, 'Performing quantile-sketch normalization in %d block(s)', ng);
    for g=0:ng-1        
        offset = g*args.block_size;        
        last = min(args.block_size+offset, nc) - offset;
        [~, srtidx] = sort(x(:, offset+(1:last)));
        for ii=1:last
            x(srtidx(:, ii), offset+ii) = sketch.mat;
        end
    end
    % without chunking
    %     [~, srtidx] = sort(x);
    %     for ii=1:nc;
    %         x(srtidx(:, ii), ii) = sketch.mat;
    %     end
else   
    % quantile normalization
    dbg(args.verbose, 'Performing quantile normalization')
    x = quantilenorm(x, 'median', true);
end

end

