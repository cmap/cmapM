function rp = rankQuery(ns, ns2rp, varargin)
% RANKQUERY Rank normalized connectivity scores using normalized score to
% rank point lookup tables.
% See also scoreToRankTransform

nsig = size(ns.mat, 1);
vq = ds_get_meta(ns2rp, 'column', 'bin_center');

% ensure that rows are ordered identically
ns = ds_slice(ns, 'rid', ns2rp.rid);
% if ~isequal(ns.rid, n2rds.rid)
%      ns2rp = ds_slice(ns2rp, 'rid', ns.rid);     
% end

% rankpoint dataset
rp = ns;

for ii=1:nsig
    rq = ns2rp.mat(ii, :);    
    % transform scores to rankpoints
    rp.mat(ii, :) = interp1(vq, rq, clip(ns.mat(ii, :), -4, 4), 'nearest');
    print_ticker(ii, 25, nsig, round(0.5*nsig/100));
end

end