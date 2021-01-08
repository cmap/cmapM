function [out_ds, out_set] = randSampleSymmetricMatrix(ds, set_size, num_sample, stat_fn)
% randSampleSymmetricMatrix random sampling of connectivity matrix
is_dataset_symmetric(ds, 1e-4);
nset = length(set_size);
set_size = floor(set_size);
assert(num_sample>0, 'Num sample must be gt 0');
num_sample = floor(num_sample);
% assert(ishandle(stat_fn), 'stat_fn is not a function handle');
stat_fn = @median_of_median;

res = zeros(num_sample, nset);
rid = gen_labels(num_sample, 'prefix', 'sample_');
cid = gen_labels(set_size, 'prefix', 'set_');
set_id = cell(num_sample*nset, 1);
set_member = cell(num_sample*nset, 1);
nfeature = length(ds.rid);
for ii = 1:nset
    for jj=1:num_sample
        this_sample = randsample(nfeature, set_size(ii));
        %this_ds = ds_slice(ds, 'ridx', this_sample, 'cidx', ...
        %                   this_sample);
        this_m = ds.mat(this_sample, this_sample);
        idx = jj + (ii-1)*num_sample;
        set_id{idx} = sprintf('%s:%s', cid{ii}, rid{jj});
        set_member{idx} = ds.rid(this_sample);
        res(jj, ii) = stat_fn(this_m);
    end
end
out_ds = mkgctstruct(res, 'rid', rid, 'cid', cid);
out_ds = ds_add_meta(out_ds, 'column', 'set_size', num2cell(set_size(:)));
out_set = mkgmtstruct(set_member, set_id, []);
end

function mom = median_of_median(m)
n = size(m, 1);
% ignore scores along the diagonal
m(1:n+1:end) = nan;
%m = m + diag(nan(size(m,1),1));
mom = nanmedian(nanmedian(m));

end

function is_dataset_symmetric(ds, tol)
assert(isds(ds), 'ds is not a valid dataset');
[nr, nc] = size(ds.mat);
assert(isequal(nr, nc), 'row and column lengths dont match')
assert(isequal(ds.rid, ds.cid));
%delta = rmse(ds.mat, ds.mat');
%assert(delta<tol, 'Values not symmetric');
end
