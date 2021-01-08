function gmt = genSizeMatchedRandomSet(univ_space, set_size, n_rep)
% genSizeMatchedRandomSet Generate uniform random sets of specified sizes.
% gmt = genSizeMatchedRandomSet(univ_space, set_size, n_rep);

n_univ = numel(univ_space);
n_set = numel(set_size);
n = n_rep * n_set;
rnd_set = cell(n, 1);
rnd_head = cell(n, 1);
rnd_desc = cell(n, 1);
% rpt = struct('set_id', rnd_head, 'rep_id', 0, 'set_size', 0);
for ii=1:n_set
%     [~, srtidx] = sort(rand(n_univ, n_rep));
%     start_idx = (ii-1) * n_rep + 1;
%     stop_idx = start_idx + n_rep - 1;
%     rnd_set(start_idx:stop_idx) = srtidx(1:set_size(ii), :);
%     
    for jj=1:n_rep
        idx = (ii-1)*n_rep + jj;
        this_set = randperm(n_univ, set_size(ii));
        rnd_set{idx} = univ_space(this_set);
        rnd_head{idx} = sprintf('RND_S%d_U%d_I%d', set_size(ii), n_univ, jj);
        rnd_desc{idx} = sprintf('S:%d U:%d I:%d', set_size(ii), n_univ, jj);
%         rpt(idx).set_id = rnd_head{idx};
%         rpt(idx).rep_id = jj;
%         rpt(idx).set_size = set_size(ii);
    end    
end

gmt = mkgmtstruct(rnd_set, rnd_head, rnd_desc);
end
