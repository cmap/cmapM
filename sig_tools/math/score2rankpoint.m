function rnkpt = score2rankpoint(x)
% SCORE2RANKPOINT Convert connectivity scores to rank points. 
% RNKPT = SCORE2RANKPOINT(X) Rank points range from [-100, 100]. The scores
% are first sorted in descending order and converted to percentile ranks
% adjusting for ties. Zero (null) scores receive a rankpoint of 0. To
% convert rankpoints to percentiles use 50-(RNKPT/2)

% set nans to nulls
x(isnan(x)) = 0;

rnkpt = rankorder(x, 'fixties', true, 'direc', 'descend',...
                  'as_percentile', true);

% set nulls to 50              
isnull = abs(x-0)<=eps(0);
rnkpt(isnull) = 50;

% clip the ranks of positive and negative scores that cross 50th
% percentile
posx = find(x>0);
rnkpt(posx(rnkpt(posx) > 50)) = 50;

negx = find(x<0);
rnkpt(negx(rnkpt(negx)<50)) = 50;

% rescale to [-100, 100]
% Note: nulls get set to zero in this scale
rnkpt = 2*(50 - rnkpt);

end
