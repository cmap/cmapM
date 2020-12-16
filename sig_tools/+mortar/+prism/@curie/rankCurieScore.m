function rnk = rankCurieScore(ncs, dim)
% rankCurieScore Convert curie scores to ranks
% rnk = rankCurieScore(ncs, dim)

dim_str = get_dim2d(dim);
rnk = ncs;
rnk.mat = rankorder(abs(rnk.mat),...
    'dim', dim_str, 'direc', 'descend',...
    'fixties', true, 'ignore_nan', true,...
    'as_percentile', true);
       

end