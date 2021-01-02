function rzplot(rr, zz, varargin)

% RZPlot plots rank of knocked down genes against z-scores of the same genes.  
% It was written to enable quick visual presentation of the effectiveness of a LITMUS validation plate
% as part of the 1k_litmus tool.
%
% Author: Ian Smith [ismith@broadinstitute.org]

%parse optional arguments
pnames = {'expression', 'color', 'title', 'savefigures', 'outfolder', 'numgenes', 'lysis_date', 'closefig'};
dflts = {100*ones(size(rr,1),size(rr,2)), [0 0 1], '', false, '', '', '', false};
args = parse_args(pnames,dflts,varargin{:});

% for prototyping only:
% size, color, symbol
exprIndicator = 'color';  


%annotate the graph with percentages for each quadrant
figure
set(gcf, 'OuterPosition', [100 100 1200 1000]);
hold on;
rr_t = 10;
zz_t = -2;
expr_t = 6;
xmin = 0.3;
xmax = 1500;
ymin = -12;
ymax = 12;

high_rr_inds = find(and(rr > rr_t, args.expression > expr_t));
low_rr_inds = find(and(rr <= rr_t, args.expression > expr_t));
high_zz_inds = find(and(zz > zz_t, args.expression > expr_t));
low_zz_inds = find(and(zz <= zz_t, args.expression > expr_t));

num_inds = numel(find(args.expression > expr_t));
bot_left = length(intersect(low_zz_inds,low_rr_inds))/num_inds;
bot_right = length(intersect(low_zz_inds,high_rr_inds))/num_inds;
top_left = length(intersect(high_zz_inds,low_rr_inds))/num_inds;
top_right = length(intersect(high_zz_inds,high_rr_inds))/num_inds;

colC = 1;
voidC = 0.8;
rectangle('Position',[xmin ymin rr_t-xmin zz_t-ymin],'FaceColor',[1-(colC*bot_left) 1 1]);
rectangle('Position',[xmin zz_t rr_t-xmin ymax-zz_t],'FaceColor',[1-(voidC*top_left) 1-(voidC*top_left) 1-(voidC*top_left)]);
rectangle('Position',[rr_t ymin xmax-rr_t zz_t-ymin],'FaceColor',[1-(voidC*bot_right) 1-(voidC*bot_right) 1-(voidC*bot_right)]);
rectangle('Position',[rr_t zz_t xmax-rr_t ymax-zz_t],'FaceColor',[1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);

%plot signature strength against rr
if strcmpi(exprIndicator, 'size')
    scatter(rr,zz,power(args.expression,2)/3,args.color,'filled');
elseif strcmpi(exprIndicator, 'color')
    exprColor = (args.expression - 4)/6;
    exprColor = min(1, max(0, exprColor));
    scatter(rr,zz,15,[exprColor zeros(numel(exprColor),1) 1-exprColor],'filled');
end
set(gcf, 'Position', [100 100 1500 1200]);
set(gca, 'Xscale', 'log');
set(gca, 'XTick', [1, 10, 100, 1000]);
set(gca, 'XTickLabel', [1, 10, 100, 1000]);
set(gcf, 'Name', ['rzplot_' texify(args.title)]);

%add cutoff value indicators
xlim([xmin xmax]);
ylim([ymin ymax]);
line(xlim,[zz_t zz_t],'Color','k','LineWidth',4);
line([rr_t rr_t],ylim,'Color','k','LineWidth',4);

%add percentage annotations
text(0.4,-11,['\fontsize{16}' sprintf('%.1f',bot_left*100) '%'],'BackgroundColor',[1-(colC*bot_left) 1 1]);
text(500,-11,['\fontsize{16}' sprintf('%.1f',bot_right*100) '%'],'BackgroundColor',[1-(voidC*bot_right) 1-(voidC*bot_right) 1-(voidC*bot_right)]);
text(0.4,10.5,['\fontsize{16}' sprintf('%.1f',top_left*100) '%'],'BackgroundColor',[1-(voidC*top_left) 1-(voidC*top_left) 1-(voidC*top_left)]);
text(500,10.5,['\fontsize{16}' sprintf('%.1f',top_right*100) '%'],'BackgroundColor',[1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);

% NumGenes, NumPerts, NumPertsExpr, LysateDate
%text(13, 11, ['\fontsize{14}' '# of genes: ', num2str(args.numgenes)], 'BackgroundColor', [1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);
text(13, 11, ['\fontsize{14}' sprintf('# of hairpins: %1.0f', numel(rr))], 'BackgroundColor', [1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);
text(13, 9.6, ['\fontsize{14}' sprintf('# of hairpins expressed: %1.0f', num_inds)], 'BackgroundColor', [1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);
%text(13, 6.8, ['\fontsize{14}' 'Lysate Date: ', args.lysis_date], 'BackgroundColor', [1-(voidC*top_right) 1-(voidC*top_right) 1-(voidC*top_right)]);

%add labels
title(['R-Z plot ', texify(args.title)]);
xlabel('Target gene rank');
ylabel('Target z-score');

hold off;

if args.savefigures
    save_image(fullfile(args.outfolder, horzcat('rzplot_', args.title)));
end

if args.closefig
    close(gcf)
end

end
