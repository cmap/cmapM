function runInterCellAnalysisWithIQR(mu_summly, q25_summly, q75_summly, wkdir, outfmt,mk_radar)
% Cross cell line analysis

axlabel = mu_summly.cid;
gplabel = mu_summly.rid;
gpsz = ds_get_meta(mu_summly, 'row', 'group_size');
mu = mu_summly.mat';
p25 = q25_summly.mat';
p75 = q75_summly.mat';

%sigma = sigma_summly.mat';
% Set missing data to zero
inan = isnan(mu);
mu(inan) = 0;
p25(inan) = 0;
p75(inan) = 0;

% prec = 100./(1 + sigma);
% prec(isnan(sigma)) = 0;

ngp = size(mu, 2);
out_path = fullfile(wkdir, 'inter_cell');
if ~isdirexist(out_path)
    mkdir(out_path);
end
if mk_radar
    fig_path = fullfile(out_path, 'radar');
    imlist = cell(ngp, 1);
    
    for ii=1:ngp
        myfigure(false);
        h = plot_radar([mu(:, ii), p25(:,ii), p75(:, ii)],...
            'axlabel', axlabel,...
            'axlim', [-100, 100],...
            'isfilled', false,...
            'dimlabel', {'Median', 'Q25', 'Q75'});
        set(h(1), 'linewidth', 2);
        if isequal(outfmt, 'png') || isequal(outfmt, 'svg')
            x1 = get(h(2),'xdata');
            x2 = get(h(3),'xdata');
            y1 = get(h(2),'ydata');
            y2 = get(h(3),'ydata');
            % add eps to allow fill to handle coincident q25 and q75
            % curves correctly
            x = [x1, x1(1), fliplr(x2)+eps, x2(1)+eps];
            y = [y1, y1(1), fliplr(y2)+eps, y2(1)+eps];
            fill_color = get_color('scarlet');
            
            % replace with fill
            hold on
            hf = fill(x, y, fill_color, 'edgecolor', fill_color, 'facealpha', 0.33, 'edgealpha', 0);
            
            % remove lines
            %     set(h(2), 'color', fill_color);
            delete(h(2:3));
            legend([h(1); hf], {'Median', 'IQR'}, 'location', 'southoutside',...
                'orientation', 'horizontal')
            legend boxoff
        end
        title(texify(sprintf('%s (n=%d)', gplabel{ii}, gpsz(ii))));
        name = validvar(gplabel{ii}, '_');
        namefig(name{1});
        
        imlist(ii) = savefigures('out', fig_path, 'mkdir', false,...
            'closefig', true, 'overwrite', true,...
            'fmt', outfmt);
    end
    if any(ismember(outfmt, {'png', 'svg'}))
        mkgallery(fullfile(wkdir, 'radar_gallery.html'), imlist,...
            'title', 'Inter cell-line Connectivity');
    end
end
mkgctx(fullfile(out_path, 'median_rankpt.gctx'), mu_summly);
mkgctx(fullfile(out_path, 'q25_rankpoint.gctx'), q25_summly);
mkgctx(fullfile(out_path, 'q75_rankpoint.gctx'), q75_summly);

end