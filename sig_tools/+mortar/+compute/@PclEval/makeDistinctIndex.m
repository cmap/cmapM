function makeDistinctIndex(inpath, cell_line, gpset)
    page_path = fullfile(inpath, 'distinct');
    mkdirnotexist(page_path);

    valid_gpnames = lower(validvar({gpset.head}, '_'));
    
    page_tbl = struct('group_id', {gpset.head}, 'url', '');
    
    jf_img = strcat(lower(validvar(strcat('jellyfish_', {gpset.head}), '_')), '.png');
    
    hm_loc = cell_line;
    nrow = length(gpset);
    nloc = length(hm_loc);
    
    
    hm_loc = cell_line;
    has_hm = false(nrow, nloc);
    hm_path = cell(nrow, nloc);

    for ii=1:nloc
        [this_fn, this_fp] = find_file(fullfile(inpath, hm_loc{ii}, 'tail_fa95.txt'));
        if ii == 1
            dist_stats = parse_record(this_fp{1});
        else
            cl_stat = parse_record(this_fp{1});
            empty_tf = isemptyrecord(cl_stat);
            cl_stat(empty_tf) = [];         
            dist_stats = join_table(dist_stats, cl_stat, 'moa', 'moa'); 
        end


        [jf_fn, jf_fp] = find_file(fullfile(inpath, hm_loc{ii}, 'jellyfish', '*.png'));
        [cmn, ithis, ihm] = intersect_ord(jf_fn, jf_img);
        has_hm(ihm, ii) = true;
        hm_path(ihm, ii) = jf_fp(ithis);    
    end

    for ii=1:nrow
        this_page = fullfile(page_path, strcat(valid_gpnames{ii}, '.html') );
        keep_hm = has_hm(ii, :);
        if any(keep_hm)
            caption_hm = hm_loc(keep_hm);
            caption = caption_hm';
            this_hm = hm_path(ii, keep_hm);
            this_img = this_hm';
            mkgallery(this_page, this_img, 'caption', caption,...
                'title', gpset(ii).head, 'ncol', 3, 'width', 315, 'height', 250)
            page_tbl(ii).url = this_page;
        end
    end
    
    mktbl(fullfile(page_path, 'index.txt'), dist_stats)
    
    dist_stats = join_table(dist_stats, page_tbl, 'moa', 'group_id');
    mk_html_table(fullfile(page_path, 'index.html'), dist_stats)

end


