function rpt = get_lindep(m)
tol = 1e-4;

inan = m>0;

% columns with no nans
wonan_cidx = all(~inan, 1);
% columns with only nans
wnan_cidx = all(inan, 1);

% rows with no nans
full_ridx = all(~inan, 2);

% row indices common to all groups
cmn_ridx = find(full_ridx);

cidx = find(~(wonan_cidx | wnan_cidx));
ridx = find(~full_ridx);

inan = sparse(double(inan(ridx, cidx)));
[Q, R, E] = qr(inan, 0);
% 
% inan = single(inan(ridx, cidx));
% [Q, R, E] = qr(inan, 0);

diagr = abs(diag(R));
rnk = find(diagr >= tol*diagr(1), 1, 'last');
% linearly independent columns
lid_cidx = sort(E(1:rnk));
% linearly dependent columns
ld_cidx = sort(E(min(rnk+1,length(E)):end));
% keep = false(size(E));
% keep(ld_cidx) = true;
nlid = length(lid_cidx);
rpt = struct('gp', gen_labels(nlid), 'size', 0, 'cidx', [], 'ridx',[]);

x = inan(:, ld_cidx);

for ii=1:nlid
    ref = inan(:, lid_cidx(ii));
    this_cidx = ld_cidx(sum(abs(bsxfun(@minus, x, ref)))<eps);
    rpt(ii).size = length(this_cidx)+1;
    rpt(ii).cidx = sort(cidx([lid_cidx(ii), this_cidx]));
    rpt(ii).ridx = union(cmn_ridx, ridx(ref<1));
    ld_cidx = setdiff(ld_cidx, this_cidx);
    x = inan(:, ld_cidx);
end

% add group with non nans
if any(wonan_cidx)
    rpt(nlid+1).gp = num2str(nlid+1);
    rpt(nlid+1).size = nnz(wonan_cidx);
    rpt(nlid+1).cidx = find(wonan_cidx);
    rpt(nlid+1).ridx = 1:size(m,1);
end


end