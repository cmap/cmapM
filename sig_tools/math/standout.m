function [ns, s] = standout(x, cutoff)
% STANDOUT An Outlier detection method

[nr, nc] = size(x);
nv = sum(~isnan(x),2);
srtx = sort(x, 2);
% 25th and 75th quantiles
p = prctile(x, [25, 75], 2);
% iqr
q = p(:,2) - p(:,1);
% mask negative outliers
mask = bsxfun(@lt, srtx, p(:,2));
srtx(mask) = nan;
s = bsxfun(@rdivide, diff(srtx,1,2), q);

% ns = sum(s >= cutoff, 2);
ns = zeros(nr, 1);
for ii=1:nr
    nout = diff([1, find(s(ii,:)>=cutoff)]);
    if ~isempty(nout)
%         disp(ii)
        ns(ii) =  sum(nv(ii) - nout(nout>1) -1);
    end
end
end