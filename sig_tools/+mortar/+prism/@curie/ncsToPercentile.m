function ps = ncsToPercentile(ncs_mat)

min_val = -4;
max_val = 4;
% bins, range of normalized scores
nbins = 10001;
vq = linspace(min_val, max_val, nbins)';
vqz = ceil(nbins/2);

% ns2rp lookup table one curve per row in ns
tx = zeros(2, nbins);

[f, v] = cdfcalc(ncs_mat(:));
% percentile ranks in descending order
p = 100-f*100;

% convert percentiles to rankpoints
r = 2*(50 - p);

% Linearly interpolate over full range of vq
pq = interp1(v, p(1:end-1), vq, 'nearest');

% Linearly interpolate over full range of vq
rq = interp1(v, r(1:end-1), vq, 'nearest');

% Set NaNs to max
inan = isnan(rq);
rq(inan) = sign(vq(inan))*100;

% store transform values
tx(1, :) = rq;
tx(2, :) = pq;

tx_labels = gen_labels(size(tx, 2), 'prefix', 'x');
ps = mkgctstruct(tx, 'rid', {'NCS2PS'; 'NCS2Q'}, 'cid', tx_labels);
ps = ds_add_meta(ps, 'column', {'bin_center'}, num2cell(vq));

end