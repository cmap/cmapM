function stats = bivariate_stats(x, y)
% BIVARIATE_STATS Compute statistics for a pair of variables
%   S = BIVARIATE_STATS(X, Y)
%   S is structure with the following fields:
%   'num_val' : Number of elements
%   'cc_pearson' : Pearson correlation coefficient
%   'cc_spearman' : Spearman correlation coefiicient
%   'rsquare' : R-square statistic
%   'adj_rsquare' : Adjusted R-square statistic
%   'ttest_tstat': Paired t-test statistic to test the hypothesis that two
%                  matched samples, in the vectors X and Y, come from
%                  distributions with equal means.
%   'ttest_h' : Decision rule for null hypothesis. H=0 indicates that the
%               null hypothesis that both X and Y come from distributions
%               with equal means, cannot be regected at the 5% significance
%               level. H=1 indicates that it can be rejected
%   'ttest_minuslog10_pvalue' : -Log10(pvalue) of the ttest
%   'ttest_ci_hi' : Upper bound of confidence interval of the true mean of
%                   X-Y
%   'ttest_ci_lo' : Lower bound of confidence interval of the true mean of
%                   X-Y
%   'ttest_sd' : The estimated population standard deviation (i.e. the 
%                std. dev. of X-Y)

x = x(:);
y = y(:);
assert(isequal(length(y), length(x)), 'X and Y must be of equal length');
inanx = isnan(x);
inany = isnan(y);
to_keep = ~inanx & ~inany;
num_masked = length(x) - nnz(to_keep);
x = x(to_keep);
y = y(to_keep);
n = length(x);

mean_x = mean(x);
mean_y = mean(y);
std_x = std(x);
std_y = std(y);

% correlations
cc_pearson = fastcorr(x, y, 'type', 'pearson');
cc_spearman = fastcorr(x, y, 'type', 'spearman');

% paired t-test to test equality of means
[ttest_h, ttest_p, ttest_ci, ttest_stats] = ttest(x, y);

% regress Y against X
%[b, bint, r, rint, rstats]=regress(y, [ones(length(x), 1), x]);
reg_stats = regstats(y,  x, 'linear', {'rsquare', 'adjrsquare'});

stats = struct('num_val', n,...
       'num_masked', num_masked,...
       'mean_x', mean_x,...
       'mean_y', mean_y,...       
       'std_x', std_x,...
       'std_y', std_y,...
       'cc_pearson', cc_pearson,...
       'cc_spearman', cc_spearman,...
       'rsquare', reg_stats.rsquare,...
       'adj_rsquare', reg_stats.adjrsquare,...
       'ttest_tstat', ttest_stats.tstat,...
       'ttest_h', ttest_h,...
       'ttest_minuslog10_pvalue', -log10(ttest_p+eps),...
       'ttest_ci_hi', ttest_ci(1),...
       'ttest_ci_lo', ttest_ci(2),...
       'ttest_sd', ttest_stats.sd);
       
end