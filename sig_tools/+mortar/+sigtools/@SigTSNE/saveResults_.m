function saveResults_(obj, out_path)
required_fields = {'args', 'ds', 'cost'};

res = obj.getResults;
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end
args = obj.getArgs;

% save results
gctwriter = @mkgctx;
gctwriter(fullfile(out_path, 'tsne.gctx'), res.ds);

if ~args.disable_table
    tsne_tbl = gct2tbl(res.ds);
    mktbl(fullfile(out_path, 'tsne.txt'), tsne_tbl);
end

mktbl(fullfile(out_path, 'stats.txt'), keepfield(res,'cost'));

% make plots
hf1 = plotTsne(res);
savefigures('out', out_path, 'mkdir', false, 'closefig', true, 'include', hf1);

end

function hf1 = plotTsne(res)
% 2d Scatter of TSNE
hf1 = myfigure(false);
scatter(res.ds.mat(:,1), res.ds.mat(:, 2));
% marker_color = get_color('blue');
% hist_color = ones(1,3)*0.8;
% hs = scatterhist(res.ds.mat(:,1),res.ds.mat(:,2),...
%     'kernel','overlay',...
%     'location','southwest',...
%     'direction','out',...
%     'markersize',2,...
%     'color', marker_color,...
%     'parent', hf1);
xlabel('tSNE 1')
ylabel('tSNE 2')
axis square
xl = xlim;
yl = ylim;
if diff(xl) > diff(yl)
    ylim(xlim);
else
    xlim(ylim);
end
yt = get(gca, 'ytick');
set(gca, 'xtick', yt);
% set(findobj(hs,'type','patch'), 'facecolor', hist_color);
title(sprintf('T-SNE, n:%d Cost:%2.3f', length(res.ds.rid), res.cost));
namefig('tsne_scatter');
end

