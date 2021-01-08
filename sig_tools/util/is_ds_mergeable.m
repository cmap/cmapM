function [yn, merge_dim] = is_ds_mergeable(ds1, ds2)

nr1 = length(ds1.rid);
nc1 = length(ds1.cid);
% nr2 = length(ds2.rid);
% nc2 = length(ds2.cid);
cmncid = intersect(ds2.cid, ds1.cid);
cmnrid = intersect(ds2.rid, ds1.rid);

nc = length(cmncid);
nr = length(cmnrid);

yn = false;
merge_dim = '';

if isempty(cmncid) && isequal(nr, nr1)
    % cids are disjoint and rids intersect : append columns
    yn = true;
    merge_dim = 'column';
elseif isempty(cmnrid) && isequal(nc, nc1)
    % rids are disjoint and cids intersect : append rows
    yn = true;
    merge_dim = 'row';
else
%     % ambiguous / name collisions
%     if isequal(nr, nr1)
%         dbg(1, 'CID collisions')
%         disp(cmncid)
%     elseif isequal(nc, nc1)
%         dbg(1, 'RID collisions')
%         disp(cmnrid)
%     else
%         dbg(1, 'CID and RID collisions')
%         disp(cmncid)
%         disp(cmnrid)
%     end
%     warning('Invalid inputs, cannot merge')
end


end
