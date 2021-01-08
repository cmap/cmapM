function quad = get_sc_quad(ss, cc, ss_cutoff, cc_cutoff)
good_ss = ss>=ss_cutoff;
good_cc = cc>=cc_cutoff;
n = length(ss);
quad.top_right = 100*nnz(good_ss & good_cc)/n;
quad.top_left = 100*nnz(good_ss & ~good_cc)/n;
quad.bot_right = 100*nnz(~good_ss & good_cc)/n;
quad.bot_left = 100*nnz(~good_ss & ~good_cc)/n;
quad.n = n;

quad.group = cell(n, 1);
quad.group(good_ss & good_cc) = {'TR'};
quad.group(good_ss & ~good_cc) = {'TL'};
quad.group(~good_ss & good_cc) = {'BR'};
quad.group(~good_ss & ~good_cc) = {'BL'};

end