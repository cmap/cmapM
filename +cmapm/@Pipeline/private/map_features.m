function [rid, rhd, rdesc, ridx]  = map_features(fmap, analytes, pool, bset, varargin)
% MAP_FEATURES analyte to feature mapping

% Expects lowercase headers

pnames = {'mapversion', ...
    'descfield', ...
    'bset_revision',...
    'affxchip'};
dflts = {'2.2', ...
    'pr_analyte_id, pr_analyte_num, pr_bset_id, pr_lua_id, pr_pool_id',...
    '', ...
    fullfile(cmapmpath, 'resources', 'HG_U133A.chip')}; % affx.chip
% 'pr_gene, pr_analyte_num, pr_bset, pr_pool, pr_lua'
arg = parse_args(pnames, dflts, varargin{:});

if ischar(fmap)
    fmap = parse_tbl(fmap, 'outfmt', 'record');
end

switch arg.mapversion
    case '2.2'
        % requires revision 
        if isempty(arg.bset_revision)
           error('Bead set revision not specified')
        end        
        % required fields
        required = {'pr_analyte_id', 'pr_bset_id', ...
            'pr_id', 'pr_lua_id', 'pr_pool_id'};
        rhd = tokenize(arg.descfield, ',', true);        
        fn = fieldnames(fmap);
        if ~isequal(length(intersect(fn, union(required, rhd))),...
                length(union(required, rhd)))
            disp(setdiff(required, fn));
            error('Required fields missing from feature map file');
        end
        % create analyte to feature map        
        filtmap = filter_table(fmap, {'pr_bset_id'},...
            {bset});
        [gcmn, gidx, ridx]=intersect_ord({filtmap.pr_analyte_id}, analytes);
        if ~isequal(length(gcmn), length(analytes))
            missing = setdiff(analytes, gcmn);
            warning ('pipedream:get_feature_map',...
                '%d features could not be mapped: pool=%s, bset=%s',...
                length(missing), pool, bset);
        end        
        % feature annotation
        rid = {filtmap(gidx).pr_id}';
        rdesc = cell(length(gidx), length(rhd));
        for ii=1:length(rhd)
            rdesc(:, ii) = {filtmap(gidx).(rhd{ii})}';
        end
        %add affx annotation
        [rhd, rdesc] = affx_annot(arg.affxchip, rid, rhd, rdesc);
        
    otherwise
        error('Unknown mapversion')
end

end
