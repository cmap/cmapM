function nrgb = get_color(c)

if ischar(c)
    c = {c};
end
p = parse_tbl(mapdir(fullfile(vdbpath, 'color', 'palette.txt')),...
    'verbose', false);
pdict = list2dict(p.color);

if all(pdict.isKey(c))
    idx = cell2mat(pdict.values(c));
    nrgb = [p.red_value(idx), p.green_value(idx), p.blue_value(idx)] / 255;
else
    disp(c(~pdict.isKey(c)));
    error('Color(s) not in palette');
end


end