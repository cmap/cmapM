function makePCLIndex(inpath, cell_line)
% generate PCL summary pages and index

% median rankpt + annotations
    [~, fp]=find_file(fullfile(inpath,'inter_cell', 'median_rankpt*.gctx'));
    ds = parse_gctx(fp{1});
    tbl = cell2struct([ds.rid, ds.rdesc],[{'group_id'};ds.rhd], 2);

    % heatmaps
    % [~, hm_img]=cellfun(@(x) validvar(x, '_'), strcat('heatmap_',ds.rid,'.png'),'uniformoutput', false);
    hm_img = strcat(lower(validvar(strcat('heatmap_',ds.rid), '_')),'.png');
    % hm_img = lower(hm_img);

    % [~, radar_img]=cellfun(@(x) validvar(x,'_'), strcat(ds.rid,'.png'),'uniformoutput', false);
    radar_img = strcat(validvar(ds.rid, '_'),'.png');
    page_name = strrep(radar_img, '.png', '.html');

    %% 
    % heatmap locations
    hm_loc = cell_line;
    nrow = length(tbl);
    nloc = length(hm_loc);

    has_hm = false(nrow, nloc);
    hm_path = cell(nrow, nloc);
    for ii=1:nloc
        [this_fn, this_fp] = find_file(fullfile(inpath, hm_loc{ii}, 'figures', '*.png'));
        [cmn, ithis, ihm] = intersect_ord(this_fn, hm_img);
        has_hm(ihm, ii) = true;
        hm_path(ihm, ii) = this_fp(ithis);
    end

    %% radar locations
    radar_path = cell(nrow, 1);
    has_radar = false(nrow, 1);
    [this_fn, this_fp] = find_file(fullfile(inpath, 'inter_cell', 'radar', '*.png'));
    [cmn, ithis, iradar] = intersect_ord(this_fn, radar_img);
    has_radar(iradar) = true;
    radar_path(iradar) = this_fp(ithis);

    %% 
    page_path = fullfile(inpath, 'pcl_pages');
    if ~isdirexist(page_path)
        mkdir(page_path);    
    end
    % loop over each group
    page_tbl = struct('group_id', {tbl.group_id}, 'url', '');

    for ii=1:nrow
        this_page = fullfile(page_path, page_name{ii});
        keep_hm = has_hm(ii, :);
        keep_radar = has_radar(ii);
        if any(keep_hm)
            caption_hm = hm_loc(keep_hm);
            caption = [caption_hm(1);{'radar'};caption_hm(2:end)];
            this_hm = hm_path(ii, keep_hm);
            this_radar = radar_path(ii);

            this_img = [this_hm(1),this_radar(1),this_hm(2:end)]';
        elseif any(keep_radar)
            caption = {'radar'};
            this_radar = radar_path(ii);        
            this_img = this_radar(1);
        end
        if any(keep_radar) || any(keep_hm)
            mkgallery(this_page, this_img, 'caption', caption,...
                'title', tbl(ii).group_id, 'ncol', 3, 'width', 315, 'height', 250)
            page_tbl(ii).url = this_page;
        end
    end
    page_tbl = page_tbl(~cellfun(@isempty, {page_tbl.url}'));

    %% make index table
    index_path = fullfile(page_path, 'index.html');
    index_txt = fullfile(page_path, 'index.txt');
    % Remove rows without scores
    %keep_rows = any(has_hm, 2);
    %scores = ds.mat(keep_rows, :);
    %grid = mergestruct(tbl(keep_rows), cell2struct(num2cell(scores),ds.cid,2));
    %grid = rmfield(grid, setdiff(fieldnames(grid), [{'group_id'; 'group_size'};ds.cid]));

    % Keep all rows
    scores = ds.mat;
    fn = validvar(ds.cid,'_');
    grid = mergestruct(tbl, cell2struct(num2cell(scores),fn,2));
    grid = rmfield(grid, setdiff(fieldnames(grid), [{'group_id'; ...
                        'group_size'};fn]));
    mk_html_table(index_path, grid, 'figures', page_tbl, 'sort_field',...
                  'group_id', 'sort_order', 'asc')
    % add url to index table
    index = grid;
    [c, ia, ib] = intersect({index.group_id}, {page_tbl.group_id});
    [index(ia).url] = page_tbl(ib).url;
    mktbl(index_txt, index);         
end