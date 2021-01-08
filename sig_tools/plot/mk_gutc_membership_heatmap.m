function mk_gutc_membership_heatmap(varargin)
%Given a compound by PCL connectivity matrix, extracts the PCL's for which
%compounds are members and makes a resulting heatmap. The PCL compound
%membership is defined by a provided pcl_annotation file
%
%Input
%       gutc_pcl_ds - GUTC connectivity results
%       pcl_annot - GMT file containing pcl annotations
%       labels - heads of metadata to use as x axis labels

config = struct('name', {'gutc_pcl_ds';...
                         '--pcl_annot';...
                         '--labels';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {''; '/cmap/data/vdb/pcl/pcl_20140402.gmt'; 'pert_iname'; false; ''; ''},...
    'help', {'';...
            '';...
            '';...
            '';...
            '';...
            ''});
opt = struct('prog', mfilename, 'desc', 'Make scatter');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

pcl_annot = parse_gmt(args.pcl_annot);
pcl_annot = gmt2tbl(pcl_annot);

% Find PCL's corresponding to cp's on the plate
uperts = unique(args.gutc_pcl_ds.cdesc(:,args.gutc_pcl_ds.cdict('pert_id')));
idx = ismember({pcl_annot.member_id},uperts);
pcl_ids = {pcl_annot(idx).group_id};
pcl_ds = ds_slice(args.gutc_pcl_ds,'rid', pcl_ids);

% Make labels
xlabels = mk_xlabels(pcl_ds,args.labels);

% Plot
[npcl,npert] = size(pcl_ds.mat);
imagesc(.5,.5,pcl_ds.mat);
ax = gca;
ax.XTick = .5:1:(npert + .5);
ax.YTick = .5:1:(npcl + .5);
ax.XTickLabel = xlabels;
ax.YTickLabel = pcl_ds.rid;
set(gca,'TickLabelInterpreter','none')
set(gca, 'TickLength',[0 0])
ax.XTickLabelRotation = 90;
colormap(rankpointmap90)
colorbar('northoutside',...
    'Ticks',[-100 -90 0 90 100],...
    'TickLabels',[-100 -90 0 90 100])

% Hacky way to make grid lines
hold on
plot([0 npert], repmat((1:(npcl-1))',1,2), 'k')
plot(repmat((1:(npert-1))',1,2), [0 npcl], 'k')
grid off

% Resize figure
set(gcf,'units','normalized','position',[.1 .1 .6 .25])
set(gcf,'PaperPositionMode','auto')
set(gca, 'FontSize', 8)

if args.save_plot
    saveas(gcf,fullfile(args.out,args.filename),'png')
    clf;
end

end

function labels = mk_xlabels(ds,labels)
    idx = ismember(ds.chd,labels);
    meta = ds.cdesc(:,idx);
     
    %Change all numeric metadata to strings
    for ii = 1:size(meta,2)
        if iscell(meta(:,ii)) && isnumeric((meta{1,ii}));
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

