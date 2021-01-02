function save_data(wkdir, rankpt_ds, rpt, sig_rpt, figure_format, varargin)
    fprintf ('Saving analysis to %s\n', wkdir);

    pnames = {'add_figs'};
    dflts = {{}};
    args = parse_args(pnames, dflts, varargin{:});
    
    fig_path = fullfile(wkdir, 'figures');
    if ~isdirexist(fig_path)
        mkdir(fig_path);
    end
    imlist = savefigures('out', fig_path,...
        'mkdir', false, 'closefig', true,...
        'overwrite', true, 'fmt', figure_format);
    
    imlist = union(imlist, args.add_figs);
    
    mkgallery(fullfile(fig_path, 'index.html'), imlist,...
        'title', 'Summly Group Analysis Results');

    % save group stats table
    rpt = rmfield(rpt, {'pw_rankpt', 'sig_id', 'row_rankpt'});
    mktbl(fullfile(wkdir, 'pcl_connectivity.txt'), rpt);

    % save member connectivity table
    mktbl(fullfile(wkdir, 'member_connectivity.txt'), sig_rpt);
    % % save rank space
    % mkgrp(fullfile(wkdir, 'rank_space.grp'), rank_space);

    % save datasets
    % if args.annotate_output
    %     score_ds = add_annotation(score_ds, sig_rpt, {'group_id'});
    %     rankpt_ds = add_annotation(rankpt_ds, sig_rpt, {'group_id'});
    % end

    % mkgctx(fullfile(wkdir, 'self_score'), score_ds);
    mkgctx(fullfile(wkdir, 'self_rankpt'), rankpt_ds);

end