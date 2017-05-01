function ds = load_qcstats(platepath, plateinfo)
% LOAD_QCSTATS Load QC stats file for each beadset in given plate.
%   DS = LOAD_QCSTATS(PLATEPATH, PLATEINFO)
if ischar(plateinfo.bset)
    bset = tokenize(plateinfo.bset, '|');
else
    bset = plateinfo.bset;
end
dsfile = cell(length(bset), 1);
lisspath  = fullfile(platepath, 'liss');
for ii=1:length(bset)
    d = dir(fullfile(lisspath, ...
        sprintf('stats_*_%s_*.txt', bset{ii})));
    disp(d);
    if length(d)==1
        dsfile{ii} = fullfile(lisspath, d.name);
        if ii>1
            ds(ii) = orderfields(parse_tbl(dsfile{ii}), ds(1));
        else
            ds(ii) = parse_tbl(dsfile{ii});
        end
    else
        error('Stats file not found at %s', fullfile(lisspath))
    end
end