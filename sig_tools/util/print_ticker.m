function print_ticker(ii, ticklen, maxlen, skiplen)
ticker = {'.','o'};

isnew = ii==maxlen || mod(ii, ticklen*skiplen)==0;
if isnew
    pct_done = round(100*ii/maxlen);
    fprintf('%3d%%\n', pct_done);
elseif mod(ii, skiplen)==0;
    fprintf('.');
end

end