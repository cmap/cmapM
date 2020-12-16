function ws = wordwrap(s, n, sep)

ns = length(s);
x = s(1:min(ns, n));
nl = ceil(ns / n);
ws = cell(nl, 1);
nsep = length(sep);
for ii=1:nl
    ib = strfind(x, sep);
    if ~isempty(ib)
        ib = ib(end);
    else
        ib = length(x);
    end
    ws{ii} = x(1:ib);
    is = ib + (ii-1)*n + 1;
    x = s(is:min(is+n, ns));
end
ws = char(ws);
end