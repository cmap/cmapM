function baseinv = mk_baseline_inv_set_plot(varargin)
%mk_baseline_inv_set_plot(varargin)
%
%Given a cell line, plot the invariant set calibration curves at baseline
%
%Example usage
%   mk_baseline_inv_set_plot({'A375'})

config = struct('name', {'cell_id';...
                         '--baseline_ds';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {'';'/cmap/data/vdb/dactyloscopy/cline_affx_n1515x22268.gctx'; false; '.'; ''},...
    'help', {'Cell line to plot (Required)';...
            'Baseline Expresion dataset';...
            'Whether to save plots (Logical)';...
            'plot output directory';...
            'filename to save plot to';});
opt = struct('prog', mfilename, 'desc', 'Make invariant set cal curve plots at baseline');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

%% Load invariant genes
inv = parse_gmx('/cmap/data/vdb/spaces/inv_eps_n80_probes.gmx');

%% Make gene to invariant set number dictionary
gene2invnum = containers.Map('KeyType','char','ValueType','Int32');
for ii = 1:length(inv)
    for jj = 1:length(inv(ii).entry)
        temp = inv(ii).head;
        num = str2num(temp(end-1:end));
        gene2invnum(inv(ii).entry{jj}) = num;
    end
end

%% Get baseline expression of invariant genes
invgenes = gene2invnum.keys;
baseinv = parse_gctx(args.baseline_ds,...
    'rid',invgenes,...
    'cid',args.cell_id,...
    'ignore_missing',true);
gene_inv_num = cell2mat(cellfun(@(s) gene2invnum(s), baseinv.rid, 'Uni', 0));

%% Plot
%jn - super hack - we only want one cell_id match. If the cell_id is not in
%the baseline_ds, parse_gctx is returning the full matrix!
if size(baseinv.mat,2) == 1
    f = figure;
    scatter(gene_inv_num,baseinv.mat)
    ax = gca;
    ax.XTick = 1:10;
    ax.XLim = [0 11];
    xlabel('Invariant Set')
    ylabel('Expression')
    title([args.cell_id 'Baseline Invariant Set Expression'])
    grid on
else
    sprintf('Cell id not found in database')
    return
end

if args.save_plot
    saveas(f,fullfile(args.out,args.filename),'png')
    clf;
end

end