function [bset2pool, pool2annot, pool2bset] = parse_poolinfo(infofile)
    info = parse_tbl(infofile, 'outfmt', 'record', 'verbose', false);
    % Valid beadsets for each pool. pool -> beadsets
    bsets = tokenize({info.exp_bset}, ',',true);
    pool2bset = containers.Map({info.id}, bsets);
    
    % pool -> chipfile, invset file, yref file, missing analytes, not duo
    exclude_fields = {'exp_pool_id', 'exp_bset_revision', 'exp_bset'};
    pool2annot = containers.Map();
    for p=1:length(info)
        v = info(p);
        v = rmfield(v, exclude_fields);
        pool2annot(info(p).id) = v;
    end
    
    bset2pool = containers.Map();
    for ii=1:length(info)
        for jj = 1:length(bsets{ii})
            bset2pool(bsets{ii}{jj}) = info(ii).exp_pool_id; 
        end
    end
end