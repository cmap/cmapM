function rore = fuse_rankscore(score_mat, rank_mat, data_type)
% FUSE_RANKSCORE Combine score and ranks to a composite float value
%   RORE = FUSE_RANKSCORE(S, R, DT) 
% If DT is 'single' then scores are assumed to lie in the range +/- 99 
% and encoded at minimum 1 digit precison and ranks are integers in the range 1-99,999
% Note that there is a loss of precision beyond 2-digits with the scores
% If DT is 'double' then
% scores are floats in the range +/- 99 at minimum 8-digit precision
% and ranks are integers in the range 1-999,999
%
switch(data_type)
case 'single'
    scale_rank = 1e2;
    scale_score = 1e3;    
case 'double'
    scale_rank = 1e2;
    scale_score = 1e8;
otherwise
    error('Invalid datatype: %s', data_type);
end
if ~isa(score_mat, data_type)
    score_mat = cast(score_mat, data_type);
end
if ~isa(rank_mat, data_type)
    rank_mat = cast(rank_mat, data_type);
end
sgn = sign(score_mat);
% handle zeros
sgn(~sgn) = 1;
rore = sgn .* (rank_mat * scale_rank + abs(round(score_mat * scale_score)/scale_score));

end