function qres = get_cached_query_results(build_id, metric, row_space, cid, rid)

cf = get_cache_file(build_id, metric, row_space);
qres = parse_gctx(cf, 'cid', cid, 'rid', rid);

end

function cf = get_cache_file(build_id, metric, row_space)
    cache = parse_tbl(fullfile(mortarpath, 'resources/query_cache.txt'), 'verbose', false);
    
    idx = strcmpi(build_id, cache.build_id) &...
          strcmpi(metric, cache.metric) &...
          strcmpi(row_space, cache.row_space);    
    assert(any(idx), 'Cache file not found for %s:%s.%s', build_id, metric, row_space);
    cf = cache.query_cache{idx};
end