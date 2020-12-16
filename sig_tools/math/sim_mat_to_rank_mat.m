function rank_sim = sim_mat_to_rank_mat(sim_mat)
%Given a pairwise similarity matrix (S), returns a symmetric pairwise
%rank similarity matrix (R) as follows
%
%R(i,j) = nnz(S(i,j) > [S(i,:) S(:,j)]/(2n)
%
%That is, R(i,j) is the proportion of entries in the i'th row and j'th
%column of S that are less than S(i,j)

n = size(sim_mat,1);

temp = tiedrank(sim_mat);
rank_sim = (temp + temp')/(2*n);

%Equivalent to the below loop (possibly modulo ties)
% for ii = 1:n
%     for jj = 1:n
%         rank_sim(ii,jj) = nnz(sim_mat(ii,jj) >= [sim_mat(ii,:) sim_mat(:,jj)'])/(2*n);
%     end
% end

end

