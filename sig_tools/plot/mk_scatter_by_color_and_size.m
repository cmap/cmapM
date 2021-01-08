function mk_scatter_by_color_and_size(varargin)
%
%
config = struct('name', {'ds';...
                         '--dim';...
                         '--color_field';...
                         '--size_field';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {''; ''; ''; ''; false; ''; ''},...
    'help', {'';...
            '';...
            '';...
            '';...
            '';...
            '';...
            ''});
opt = struct('prog', mfilename, 'desc', 'Make scatter');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

ds = args.ds;

if isequal(args.dim, 'row')
    size_meta = ds.rdesc(:,ds.rdict(args.size_field));
    color_meta = ds.rdesc(:,ds.rdict(args.color_field));
elseif isequal(args.dim, 'column')
    size_meta = ds.cdesc(:,ds.cdict(args.size_field));
    color_meta = ds.cdesc(:,ds.cdict(args.color_field));
end

%Convert to numerical matrices if needed
if iscell(size_meta)
    size_meta = cell2mat(size_meta);
end

marker_size = 50*(1:length(unique(size_meta)));

color_triplets = [
    1, 0, 1;...
    0, 1, 1;...
    1, 0, 0;...
    0, 1, 0;...
    0, 0, 1;...
    0, 0, 0;...
    1, 1, 0];

marker_color = color_triplets(1:length(unique(color_meta)),:);

% f = figure;
% ums = unique(size_meta);
% umc = unique(color_meta);
% for ii = 1:length(unique(size_meta))
%     for jj = 1:length(umc)
%         idx1 = (size_meta == ums(ii));
%         idx2 = strcmp(umc(jj),color_meta);
%         idx = idx1 & idx2;
%         temp = scatter(ds.mat(idx,1),ds.mat(idx,2),...
%                 marker_size(ii),... 
%                 marker_color(jj,:),...
%                 'CData',marker_color(jj,:));
%         hold on
%     end
% end

f = figure;
ums = unique(size_meta);
umc = unique(color_meta);
for ii = 1:length(umc)
    for jj = 1:length(ums)
        idx1 = (size_meta == ums(jj));
        idx2 = strcmp(umc(ii),color_meta);
        idx = idx1 & idx2;
        this_plot = scatter(ds.mat(idx,1),ds.mat(idx,2),...
                marker_size(jj),... 
                marker_color(ii,:));
        hold on
    end
    h(ii) = this_plot;
end

grid on
xlabel(ds.cid(1),'Interpreter','none')
ylabel(ds.cid(2),'Interpreter','none')

legend(h,umc,'Location','eastoutside');

if args.save_plot
    saveas(f,fullfile(args.out,args.filename),'png')
    clf;
end

end

