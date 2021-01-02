function print_ticker(ii, ticklen, maxlen)
ticker = {'.','o'};

istick = mod(ii, ticklen)==0|| ii==maxlen;
if istick
    pct_done = round(100*ii/maxlen);
    fprintf('%3d%%\n', pct_done);
else
    fprintf('.');
end

end