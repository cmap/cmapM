% MIT_HEATMAP Display heatmap of data matrix using MIT color scheme.
% MIT_HEATMAP(M)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function hf = mit_heatmap(m, varargin)

pnames = {'-minstd','-maxstd','-colorbar','parent'};
dflts = { -3, 3, true, gca };
arg = parse_args(pnames, dflts, varargin{:});

% if arg.parent
%     hf = figure;
% else
%      axes(gca);
% end
axes(arg.parent);

imagesc(row_normalize(m))
caxis([arg.minstd, arg.maxstd])
colormap(bluepink)

if arg.colorbar
    colorbar
end
