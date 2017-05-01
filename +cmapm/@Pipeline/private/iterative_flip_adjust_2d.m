function [adjds, flipstats, prpt] = iterative_flip_adjust_2d(ds, cnt, varargin)
% ITERATIVE_FLIP_ADJUST_2D Flip detection and corrrection.

pname = {'maxiter', 'flip_cutoff', 'flip_method','flip_freq', 'not_duo', 'debug'};
dflts = {10, 0.4, 'linear', 3, 0, false};
args = parse_args(pname, dflts, varargin{:});

if ~isstruct(ds) && ~isequal(length(ds), 2) &&...
        ~isstruct(cnt) && ~isequal(length(cnt), 2)
    error('Invalid Input');
end
[nfeature, nsample] = size(ds(1).mat);
adjds = ds;
flipstats = zeros(nfeature, nsample);
prpt = ds;
prpt(1).mat = zeros(nfeature, nsample);
prpt(2).mat = zeros(nfeature, nsample);
for ii = 1:nfeature
    xraw = [ds(1).mat(ii,:); ds(2).mat(ii,:)]';
    xcnt = [cnt(1).mat(ii,:); cnt(2).mat(ii,:)]';
    x = [xraw(:), xcnt(:)];    
    if ~any(var(x, 0)<eps) && ~ismember(ii, args.not_duo)
        % skip missing analytes
        change = true;
        iter = 1;
        while change && iter <= args.maxiter
            [adj, flips, posterior, logp] = flip_correction_nd(x, args.flip_cutoff, args.flip_method);
            flipstats(ii, flips) = flipstats(ii, flips) + 1;
            change = nnz(flipstats(ii,flips) <= args.flip_freq)>0;
            dbg(args.debug, '%d,', flips)
            iter = iter + 1;            
            x = adj;
        end
        dbg(args.debug, 'feature:%d, niter:%d',ii,iter)        
        adjds(1).mat(ii,:) = adj(1:nsample, 1);
        adjds(2).mat(ii,:) = adj((1:nsample)+nsample, 1);
        %posterior probabilities
        prpt(1).mat(ii, :) = posterior(1:nsample, 1);
        prpt(2).mat(ii, :) = posterior((1:nsample)+nsample, 2);
    end    
    if args.debug && nnz(flipstats(ii, :)>=args.flip_freq)
        figure
        cidx=find(flipstats(ii,:)>1);
        scatter(adj(:,1),adj(:,2), 'x')
        hold on
        scatter(adj(cidx,1),adj(cidx,2),'ro')
        axis tight
        title(texify(sprintf('Analyte %d nflip:%d', ii, length(cidx))))
    end
end
