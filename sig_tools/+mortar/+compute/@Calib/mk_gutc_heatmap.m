function mk_gutc_heatmap(varargin)
%Given a compound by PCL connectivity matrix, extracts the PCL's for which
%compounds are members and makes a resulting heatmap. The PCL compound
%membership is defined by a provided pcl_annotation file
%
%Input
%       conn_to_ref - GUTC connectivity results
%       pcl_annot - GMT file containing pcl annotations
%       labels - heads of metadata to use as x axis labels. Order
%       determines sorting in heatmap.

TRT_CP = 'trt_cp';
TRT_POSCON = 'trt_poscon';
OUT_NAME_NO_CTL = 'ps_pcl_summary_treated.gctx';
OUT_NAME_CTL = 'ps_pcl_summary.gctx';

config = struct('name', {'conn_to_ref';...
                         '--pcl_annot';...
                         '--labels';...
                         '--pcls_to_display';...
                         '--include_ctl';...
                         '--save_plot';...
                         '--save_fig';...
                         '--save_gct';...
                         '--out';...
                         '--filename';...
                         '--show_figure'},...
    'default', {''; ...
        '/cmap/data/vdb/pcl/pcl_n171_20170201.gmt';...
        'pert_iname';...
        ''; ...
        false;...
        true;...
        false;...
        true;...
        ''; ...
        'GUTC_heatmap'; ...
        false},...
    'help', {'Path to PCL connectivity GCTX from GUTC analysis';...
            'GMT file containing pcl annotations';...
            'Metadata headers to use as x-axis labels. Order determines sorting.';...
            'List of PCLs with expected connections to display in heatmap';...
            'Include DMSO/Untrted signatures in heatmap';...
            'Logical.Save heatmap';...
            'Logical. Save FIG file';...
            'Logical.Save subsetted connectivity matrix';...
            'Output directory';...
            'Filename of heatmap plot'; ...
            'Show figure windows'});
opt = struct('prog', mfilename, 'desc', 'Make scatter');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if ~isstruct(args.conn_to_ref)
    if isfileexist(args.conn_to_ref)
        [~,args.filename,~] = fileparts(args.conn_to_ref);
        conn_to_ref = parse_gctx(args.conn_to_ref);
    else
        error('File not found: %s', args.conn_to_ref);
    end
else
    conn_to_ref = args.conn_to_ref;
end

if ~(args.include_ctl)
    pert_types = conn_to_ref.cdesc(:,conn_to_ref.cdict('pert_type'));
    idx = strcmp(pert_types, TRT_CP) | strcmp(pert_types, TRT_POSCON);
    conn_to_ref = ds_slice(conn_to_ref, 'cidx', idx);
end

conn_to_ref = sort_gct_cols(conn_to_ref, args.labels);


% Find PCL's corresponding to cp's on the plate if no PCLs provided
pcl_annot = parse_gmt(args.pcl_annot);
pcl_annot = gmt2tbl(pcl_annot);
uperts = unique(conn_to_ref.cdesc(:,conn_to_ref.cdict('pert_id')));
idx = ismember({pcl_annot.member_id},uperts);
pcl_ids = {pcl_annot(idx).group_id};
pcl_ids = union(pcl_ids, args.pcls_to_display);

pcls_present = ismember(pcl_ids,conn_to_ref.rid);
if ~any(pcls_present)
    error('No corresponding PCLs found between pcl_annot or pcls_to_display and conn_to_ref');
elseif any(~pcls_present)
    missing = pcl_ids(~pcls_present);
    fprintf('The following PCLs were not found within conn_to_ref: \n')
    for i = 1:length(missing)
        dbg(1, '%s', missing{i})
    end
    dbg(1, 'Continuing...');
    pcl_ids = pcl_ids(pcls_present);
end
    

pcl_ds = ds_slice(conn_to_ref,'rid', pcl_ids, 'ignore_missing', 1);


% Make labels
xlabels = mk_xlabels(pcl_ds,args.labels);

% Plot
if ~args.show_figure
    myfigure(false);
else
    figure;
end

[npcl,npert] = size(pcl_ds.mat);
imagesc(.5,.5,pcl_ds.mat);
ax = gca;
ax.XTick = .5:1:(npert + .5);
ax.YTick = .5:1:(npcl + .5);
ax.XTickLabel = xlabels;
ax.YTickLabel = pcl_ds.rid;
ax.XAxisLocation = 'top';
set(gca,'TickLabelInterpreter','none')
set(gca, 'TickLength',[0 0])
ax.XTickLabelRotation = 45;
colormap(taumap_redblue90)
c = colorbar('southoutside');
caxis([-100 100]);

% Hacky way to make grid lines
hold on
if (npcl>1)
    plot([0 npert], repmat((1:(npcl-1))',1,2)', 'k')
end
if (npert>1)
    plot(repmat((1:(npert-1))',1,2)', [0 npcl], 'k')
end
grid off

% Resize figure
set(gcf,'units','normalized','position',[.1 .1 .6 .25])
set(gcf,'PaperPositionMode','auto')
set(gca, 'FontSize', 9)

cbprops = [ax.Position(1) 0.05 .3 .04];
set(c, 'Position', cbprops,...
    'Ticks',[-90 0 90]);

namefig(gcf,sprintf('%s_n%dx%d', args.filename,npert, npcl));


if args.save_plot
    saveas(gcf,fullfile(args.out,sprintf('%s_n%dx%d', args.filename,npert, npcl)),'png');
end
if args.save_fig
    saveas(gcf,fullfile(args.out,sprintf('%s_n%dx%d', args.filename,npert, npcl)),'fig');
end

if (args.save_gct && ~args.include_ctl)
    mkgctx(fullfile(args.out,OUT_NAME_NO_CTL), conn_to_ref);
elseif (args.save_gct)
    mkgctx(fullfile(args.out,OUT_NAME_CTL), conn_to_ref);
end
end

function labels = mk_xlabels(ds,labels)
    idx = ismember(ds.chd,labels);
    meta = ds.cdesc(:,idx);
     
    %Change all numeric metadata to strings
    for ii = 1:size(meta,2)
        if iscell(meta(:,ii)) && isnumeric((meta{1,ii}))
            meta(:,ii) = cellstr(num2str(cell2mat(meta(:,ii))));
        end
    end
    
    %If more than one column, concatenate the metadata
    if size(meta,2) > 1
        for jj = 1:size(meta,1)
            labels{jj} = strrep(strjoin(cellstr(meta(jj,:)),'_'),' ','');
        end
    else
        labels = meta;
    end
end

function sorted_gct = sort_gct_cols(gct_ds, fields)
    nf = length(fields);
    colnums = NaN(1, nf);
    for i = 1:nf
        if (isKey(gct_ds.cdict, fields{i}))
            colnums(i) = gct_ds.cdict(fields{i});
        else
            error('%s is not a field in GCT struct', fields{i});
        end
    end
    
    sorted_gct = gct_ds;
    [sorted_gct.cdesc, order] = sortrows(gct_ds.cdesc, colnums);
    sorted_gct.mat = gct_ds.mat(:, order);
end
