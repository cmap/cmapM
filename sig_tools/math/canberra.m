function d = canberra(r)
[nr, nc] = size(r);
d = zeros(nc);
% reversed rank
revr = nr - r + 1;
for ii=1:nc
    delta = abs(bsxfun(@minus, r, r(:,ii)));
    tot = bsxfun(@plus, r, r(:,ii));
    d1 = delta ./ tot;
    d2 = delta ./ (2*(nr+1) - tot);
    d(:, ii) = sum(max(d1, d2));
    d(ii, :) = d(:, ii);
end

end