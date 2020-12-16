function [rhd, rdesc] = affx_annot(chipfile, rid, rhd, rdesc)
% AFFX_ANNOT add Affy annotation.

rdict = list2dict(rhd);
% read annotations from chip file
ann = parse_tbl(chipfile, 'detect_numeric', false);
d = list2dict(ann.pr_id);
fn = setdiff(fieldnames(ann), {'pr_id'});
isvalid = d.isKey(rid);
n = length(rid);
empty_val = {'-666'};
for ii=1:length(fn)
    val = cell(n, 1);
    if nnz(isvalid)
        idx = cell2mat(d.values(rid(isvalid)));
        val(isvalid) = ann.(fn{ii})(idx);
    end
    val(~isvalid) = empty_val;
    if rdict.isKey(fn{ii})
        rdesc(:, rdict(fn{ii})) = val;
    else
        rdesc(:, end + 1) = val;
        rhd = [rhd(:); fn{ii}];
    end
end
end