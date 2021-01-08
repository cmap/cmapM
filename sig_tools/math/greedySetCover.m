function sc = greedySetCover(s)

% members x sets
bm = set2ds(s);

% uncovered elements
u = any(bm.mat, 2);
% set cover solution
sc = false(length(bm.cid), 1);

while any(u)

% set sizes
ss = sum(bm.mat, 1);
% select largest set
imax_s = imax(ss);
% exclude covered elements
bm.mat(bm.mat(:, imax_s)>0, :) = 0;

% add set to set cover
sc(imax_s) = true;

% update uncovered elements
u = any(bm.mat, 2);

end


end


function bm = set2bm(s)
fn = fieldnames(t);
set_idx = grp2idx({tbl.(fn{1})}');
memb_idx = grp2idx({tbl.(fn{2})}');
bm = false(length(memb_idx), length(set_idx));
end

function bm = table2bm(t)
fn = fieldnames(t);
set_idx = grp2idx({tbl.(fn{1})}');
memb_idx = grp2idx({tbl.(fn{2})}');
bm = false(length(memb_idx), length(set_idx));

end