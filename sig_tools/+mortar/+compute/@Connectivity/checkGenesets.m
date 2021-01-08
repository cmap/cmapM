function [up, dn] = checkGenesets(up, dn, rdict, es_tail)
% Validate and filter spurious features
switch lower(es_tail)
    case 'both'
        % Validate genesets
        ns = length(up);
        assert(isequal(ns, length(dn)), 'BAD_QUERY: Number of up and down genesets dont match');
        % uptag_name = regexprep(upper({up.head}'), '_UP$', '');
        % dntag_name = regexprep(upper({dn.head}'), '_DN$', '');
        % assert (isequal(uptag_name, dntag_name), ...
        %         'BAD_TAGS: up and down tags headers dont match!');
        
        % check if probesets are in the feature space and remove probesets not in
        % feature space
        for ii=1:ns
            assert(~isequal(up(ii).entry, dn(ii).entry),...
                'BAD_QUERY: (%s,%s) up and downsets are identical',...
                up(ii).head, dn(ii).head);
            is_up_rid = rdict.iskey(up(ii).entry);
            if any(~is_up_rid)
                up(ii).entry = up(ii).entry(is_up_rid);
                up(ii).len = nnz(is_up_rid);
                assert(up(ii).len>0,...
                    'BAD_QUERY: No valid features found for geneset: %s', up(ii).head);
            end
            
            is_dn_rid = rdict.iskey(dn(ii).entry);
            if any(~is_dn_rid)
                dn(ii).entry = dn(ii).entry(is_dn_rid);
                dn(ii).len = nnz(is_dn_rid);
                assert(dn(ii).len>0,...
                    'BAD_QUERY: No valid features found for geneset: %s', dn(ii).head);
            end
            % check for overlapping features
            cmn_features = intersect(up(ii).entry, dn(ii).entry);
            if ~isempty(cmn_features)
                disp(cmn_features);
                error(['BAD_QUERY: %d Feature(s) present in both UP ' ...
                       'and DOWN sets'], length(cmn_features));
            end
        end
    case 'up'
        % Validate up genesets
        ns = length(up);

        % check if probesets are in the feature space and remove probesets not in
        % feature space
        for ii=1:ns
            is_up_rid = rdict.iskey(up(ii).entry);
            if any(~is_up_rid)
                up(ii).entry = up(ii).entry(is_up_rid);
                up(ii).len = nnz(is_up_rid);
                assert(up(ii).len>0,...
                    'BAD_QUERY: No valid features found for geneset: %s', up(ii).head);
            end
        end
    case 'down'
        % Validate down genesets
        ns = length(dn);
        
        % check if probesets are in the feature space and remove probesets not in
        % feature space
        for ii=1:ns
            is_dn_rid = rdict.iskey(dn(ii).entry);
            if any(~is_dn_rid)
                dn(ii).entry = dn(ii).entry(is_dn_rid);
                dn(ii).len = nnz(is_dn_rid);
                assert(dn(ii).len>0,...
                    'BAD_QUERY: No valid features found for geneset: %s', dn(ii).head);
            end
        end
end
end