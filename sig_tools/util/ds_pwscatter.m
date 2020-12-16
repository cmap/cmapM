function ds_pwscatter(varargin)

[help_flag, args] = getArgs(varargin{:});
if ~help_flag
    ds1 = parse_gctx(args.ds1);
    ds2 = parse_gctx(args.ds2);
    % expect dimensionality to match
    [nr1, nc1] = size(ds1.mat);
    [nr2, nc2] = size(ds2.mat);
    dim_str = get_dim2d(args.dim);

    switch(dim_str)
        case 'row'
            title_str = get_groupvar(gctmeta(ds1, 'row'), [], args.label_field);
            xlbl = strcat(args.ds1_name, ':', get_groupvar(gctmeta(ds1, 'row'), [], args.label_field));
            ylbl = strcat(args.ds2_name, ':', get_groupvar(gctmeta(ds2, 'row'), [], args.label_field));
            plot_xy(ds1.mat', ds2.mat', 'o', args.xlim, args.ylim, xlbl, ylbl, title_str);
        case 'column'
            plot_xy(ds1.mat, ds2.mat, 'o', args.xlim, args.ylim, xlbl, ylbl, title_str);
    end
    
end

end
function plot_xy(x1, x2, sym, xlimit, ylimit, xlbl, ylbl, title_str)
    [nr, nc] = size(x1);
    for ii=1:nc
        figure
        scatter(x1(:, ii), x2(:, ii), sym, 'filled')        
        axis square
        xlabel(texify(sprintf('%s', xlbl{ii})))
        ylabel(texify(sprintf('%s', ylbl{ii})))
        xlim(xlimit)
        ylim(ylimit)
        refline
        axis tight
        title(texify(title_str{ii}))
        namefig(sprintf('xy_%s', title_str{ii}));
    end
end

function [help_flag, args] = getArgs(varargin)
config = struct('name', {'ds1'; 'ds2'; '--dim'; '--label_field'; '--xlim'; '--ylim'; '--ds1_name'; '--ds2_name'},...
    'default', {''; ''; 'column'; '_id'; 'auto'; 'auto'; ''; ''},...
    'help', {'Dataset 1'; 'Dataset 2';
    'Dimension to operate on'; 'Metadata field to use as label';
    'X-axis limit'; 'Y-axis limit';
    'Dataset1 label'; 'Dataset2 label'});
opt = struct('prog', mfilename, 'desc', 'Scatter Plots of two datasets');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
if ~help_flag
    assert(~isempty(args.ds1), 'Dataset1 not specified')
    assert(~isempty(args.ds2), 'Dataset2 not specified')
    if ~strcmp('auto', args.xlim)
        args.xlim = str2double(strsplit(args.xlim));
    end
    if ~strcmp('auto', args.ylim)
        args.ylim = str2double(strsplit(args.ylim));
    end
    if isempty(args.ds1_name)
        if isds(args.ds1)
            bn = basename(args.ds1.src);
            [~, args.ds1_name]=strip_dim(bn{1});
        else
            args.ds1_name = 'DS1';
        end
    end
    if isempty(args.ds2_name)
        if isds(args.ds2)
            bn = basename(args.ds2.src);
            [~, args.ds2_name]=strip_dim(bn{1});
        else
            args.ds2_name = 'DS2';
        end
    end
end

end