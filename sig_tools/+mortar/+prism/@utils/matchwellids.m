% returns dataset ds with well ids (cid) that match those in annotation struct
% dsmatch = matchwellids(ds,annot)

function dsmatch = matchwellids(ds,annot)

dsmatch = ds;

if prod(ismember(ds.cid,{annot.well}))==1
    return;
end

%extract index - first integer in cid
%format of ds.cid is 'int(int,alphaint)' e.g. 1(1,A01)
ind = regexprep(ds.cid,{'\([0-9]*,[A-Z][0-9]*\)'},'');
ind = cellfun(@str2num,ind);
dsmatch.cid = {annot(ind).well};