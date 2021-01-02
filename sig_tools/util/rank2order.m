function ord = rank2order(r)
% Rank2Order Convert ranks to row order
[nr, nc] = size(r);
ord = nan(size(r));
for ii=1:nc
    ord(r(:,ii),ii) = 1:nr;
end
end