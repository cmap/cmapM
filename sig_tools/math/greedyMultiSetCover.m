function [sc_tbl, sc] = greedyMultiSetCover(s, k)

% members x sets
    bm = set2ds(s);

    % each element should be covered at least k times
    % number of uncovered elements
    u = sum(bm.mat, 2);
    
    min_coverage = min(u);    
    assert(min_coverage >= k, 'Some elements are covered by less than k sets');
    
    % set cover solution
    sc = false(length(bm.cid), 1);
    
    while any(u > min_coverage - 2)
        
        % set sizes
        ss = sum(bm.mat, 1);
        % select largest set
        imax_s = imax(ss);
        
        % update uncovered elements
        u = u - bm.mat(:, imax_s);
        
        % exclude covered elements
        bm.mat(:, imax_s) = 0;
        bm.mat(u <= min_coverage - 2, :) = 0;
        
        % add set to set cover
        sc(imax_s) = true;
        
    end    
    sc_tbl = gmt2tbl(s(sc));
end