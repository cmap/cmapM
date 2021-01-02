function ns2rp = scoreToRankTransform(ns, ts, varargin)
% SCORETORANKTRANSFORM Compute normalized score to rankpoint lookup tables.
%   NS2RP = SCORETORANKTRANSFORM(NS, TS) 

% 
% nsig = size(ns.mat, 1);
% 
% % bins, range of normalized scores
% nbins = 10001;
% vq = linspace(-4, 4, nbins)';
% vqz = ceil(nbins/2);

is_ts = ismember(ns.cid, ts.rid(ds_get_meta(ts, 'row', 'is_touchstone')>0))';
ns2rp = mortar.compute.Gutc.scoreToPercentile(ds_slice(ns, 'cid', ns.cid(is_ts)), 'row', -4, 4, 10001);

% % ns2rp lookup table one curve per row in ns
% tx = zeros(nsig, nbins);
% 
% for ii=1:nsig
%     [f, v] = cdfcalc(ns.mat(ii, is_ts));
%     
%     % percentile ranks in descending order
%     r = 100-f*100;
%     % clip the ranks of positive and negative scores that cross 50th
%     % percentile
%     posv = find(v>0);
%     r(posv(r(posv)>50)) = 50;    
%     negv = find(v<0);
%     r(negv(r(negv)<50)) = 50;
%     
%     % convert percentiles to rankpoints
%     r = 2*(50-r);
%     
%     % Linearly interpolate over full range of vq 
%     rq = interp1(v, r(1:end-1), vq, 'nearest');
%         
%     % negative score closest to zero
%     zn = max(ns.mat(ii, is_ts & ns.mat(ii, :)<0));
%     % positive score closest to zero
%     zp = min(ns.mat(ii, is_ts & ns.mat(ii,:)>0));
%     
%     % find null regions
%     % find nearest vq index
%     vqidx = interp1(vq, 1:length(vq), [zn, zp], 'nearest');
%     xn = vq(vqidx(1));
%     % find nearest rq
%     yn = interp1(vq, rq, xn, 'nearest');
%     % do the same for positive scores
%     xp = vq(vqidx(2));
%     yp = interp1(vq, rq, xp, 'nearest');
% 
%     % linearly interpolate the null regions
%     nidx = vqidx(1):vqz;
%     pidx = vqz:vqidx(2);        
%     rq(nidx) = yn*vq(nidx)/xn;
%     rq(pidx) = yp*vq(pidx)/xp;
%     
%     % Set NaNs to max
%     inan = isnan(rq);
%     rq(inan) = sign(vq(inan))*100;    
%     
%     % store transform values
%     tx(ii, :) = rq;        
%     print_ticker(ii, 25, nsig, round(0.5*nsig/100));
% end
% 
% tx_labels = gen_labels(size(tx, 2), 'prefix', 'x');
% ns2rp = mkgctstruct(tx, 'rid', ns.rid, 'cid', tx_labels);
% ns2rp = ds_add_meta(ns2rp, 'column', {'bin_center'}, num2cell(vq));

end