function ds = fix_sample_meta(ds)
% FIX_SAMPLE_META Fix sample annotations.

% rename / merge fields beginning with 'exp_'
fixedhd = regexprep(ds.chd, '^exp_', '');
[chd, nl] = getcls(fixedhd);
nhd = length(chd);
nc = size(ds.cdesc, 1);
cdesc = cell(nc, nhd);
for ii=1:nhd
    cidx = find(nl == ii);
    if isequal(length(cidx),1)
        cdesc(:, ii) = ds.cdesc(:, cidx);
    else
        % merge duplicate fields
        tmp = ds.cdesc(:, cidx);
        [~, keepidx] = max(~cellfun(@isempty, tmp), [], 2);
        for jj=1:nc
            cdesc(jj, ii) = tmp(jj, keepidx(jj));
        end
    end
end

ds.chd = chd;
ds.cdesc = cdesc;
ds.cdict = list2dict(ds.chd);
