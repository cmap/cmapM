function plot_sig_hits(x, ridx)
figure;
[srtx, srti] = sort(x);
[a,b] = sort(srti);
iridx = b(ridx);
plot(srtx)
hold on
plot(iridx, srtx(iridx), 'ro')

end