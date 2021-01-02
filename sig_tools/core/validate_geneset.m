function gs = validate_geneset(gs, fs)
% Validate genesets
ns = length(gs);
rdict = list2dict(fs);

% check if probesets are in the feature space and remove probesets not in
% feature space
for ii=1:ns
    is_rid = rdict.isKey(gs(ii).entry);
    if any(~is_rid)
        gs(ii).entry = gs(ii).entry(is_rid);
        gs(ii).len = nnz(is_rid);
        assert(gs(ii).len>0, 'No valid features found for geneset: %s', gs(ii).head);
    end
    
end
end