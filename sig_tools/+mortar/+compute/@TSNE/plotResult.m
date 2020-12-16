function rpt = plotResult(ts, outpath, varargin)

args = getArgs(varargin{:});

ts = parse_gctx(ts);
% scale data to -50, +50 range
scale_factor = max(max(abs(ts.mat(:))), 50);
ts.mat = 50*ts.mat/scale_factor;

% meta data
pert_iname = ds_get_meta(ts,'row', {'pert_iname'});
cell_id = ds_get_meta(ts,'row', {'cell_id'});
pert_idose = ds_get_meta(ts,'row', {'pert_idose'});
pert_dose_raw = str2double(regexprep(pert_idose, ' *[uµ]m$', '', 'ignorecase'));
% discretize doses according to bins
pert_dose = discretize(pert_dose_raw, args.dose_bins);
pert_dose_str = num2cellstr(pert_dose);

sig_id = ts.rid;
[cnd, nld] = getcls(pert_dose_str);
[cnc, nlc] = getcls(cell_id);
[cnn, nln] = getcls(pert_iname);
nsig = accumarray(nln,ones(size(nln)));
showfig = false;
savefig = true;
uc = unique(cell_id);
pal = get_palette(length(uc), 'scheme', 'motley20');
pal_dict = containers.Map(uc, num2cell(pal,2));

rpt = struct('pert_iname', cnn, 'num_sig', num2cell(nsig),...
    'cell_id', '', 'concordance', '',...
    'best_cell_id', '', 'best_concordance','',...
    'url', '');

for ii=1:length(cnn)
    this =  find(nln==ii);
    dbg(1, '%d/%d', ii, length(cnn));
    myfigure(showfig);
    x = ts.mat(this, 1);
    y = ts.mat(this, 2);
    
    d = pert_dose(this);
    c = cell_id(this);
    [cnd, nld] = getcls(d);
    dsz = accumarray(nld, ones(size(nld)));
    dval = [num2cellstr(cnd), num2cell(dsz)]';
    dlbl = tokenize(sprintf('%s (%d)\n', dval{:}), sprintf('\n'));
    dlbl = dlbl(1:end-1);
    
    [cnc, nlc] = getcls(c);
    csz = accumarray(nlc, ones(size(nlc)));
    cval = [cnc, num2cell(csz)]';
    clbl = tokenize(sprintf('%s (%d)\n', cval{:}), sprintf('\n'));
    clbl = clbl(1:end-1);
    
    nc = length(cnc);
    nd = length(cnd);    
    marker_sz = logspace(log10(4), log10(13), nd);
%     sz = marker_sz(nd-nld+1);
    sz = marker_sz(nld);
    
    % stats
    [lbl, sigma]=grpstats([x, y], c, {'gname', @(x) mad(x, 1, 1)});
    conc = 1./clip(mean(sigma, 2), 0.1, inf);
    [srt_conc, srti] = sort(conc, 'descend');
    
    rpt(ii).cell_id = lbl(srti);
    rpt(ii).concordance = srt_conc;
    rpt(ii).best_concordance = srt_conc(1);
    rpt(ii).best_cell_id = lbl{srti(1)};
    
    hl = zeros(nc*nd, 1);
    
    for ic=1:length(cnc)
        for id = 1:length(cnd)
            keep = find(nld==id & nlc ==ic);
            if ~isempty(keep)
                hl(id+(ic-1)*nd) = plot(x(keep), y(keep), 'o', 'linewidth', 1.5, 'markersize', sz(keep(1)), 'color', pal_dict(cnc{ic}));
                hold on
            end
        end
    end
    axis square
    % axis limits
    xlim([-50, 50])
    ylim([-50, 50])
    % hide the scale, since its not informative
    set(gca, 'xtick',[], 'ytick', []);
    grid off
    title(sprintf('%s n=%d', texify(cnn{ii}), nsig(ii)));
    namefig(cnn{ii});
    % handles nd x nc
    hmat = reshape(hl,nd,nc);
    [a, b] = find(hmat);
    [ub,ib] = unique(b);
    [ua,ia] = unique(a);
    
    hc = hmat(sub2ind(size(hmat),a(ib),b(ib)));
    hd = hmat(sub2ind(size(hmat),a(ia),b(ia)));
    
    % legend for cell line
    lh = legend(hc, clbl, 'location', 'northeastoutside', 'fontsize', 8);
    % uniform marker size
    lp = findobj(lh, 'type', 'line');
    set(lp, 'markersize', 10);    
    lh_pos = get(lh, 'position');
    % keep a copy (needed for two legends)
    lhc = copyobj(lh, gcf);
    
    % legend for dose
    lhd = legend(hd, dlbl, 'location', 'southeastoutside', 'fontsize', 8);

    % fix position of lhc
    lhd_pos = get(lhd, 'position');
    set(lhc,'position',[lhd_pos(1),lh_pos(2:end)])
    
    if (savefig)
        url = savefigures('out', outpath,...
                          'mkdir', false,...
                          'closefig', true,...
                          'fmt', args.outfmt);
        rpt(ii).url = url{1};
    end
end

end

function args = getArgs(varargin)
param = {'--dose_bins',...
    '--outfmt',...
    };
default = {[-666, 0.04, 0.12, 0.37, 1.11, 2.5 3.33, 5, 10, 33.33, 100],...
    'png',...
    };
config = struct('name', param, 'default', default);
opt = struct('prog', mfilename);
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

end
