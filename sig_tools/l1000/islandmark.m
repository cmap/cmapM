function [islm, lmps] = islandmark(g, pool, varargin)

pnames = {'isgene', 'bset_revision'};
dflts = {false, 'r1'};
args = parse_args(pnames, dflts, varargin{:});

info_file = fullfile(mortarconfig('l1k_config_path'), 'L1000_poolinfo.txt');
ignore_genes = {'CAL01','CAL02','CAL03',...
    'CAL04','CAL05','CAL06',...
    'CAL07','CAL08','CAL09',...
    'CAL10','---'};

if ischar(g)
    g={g};
end

if args.isgene
    ps = genesym2ps(g, 'ignore_missing', true);
else
    ps = g;
end
ng = length(ps);

if ischar(pool)
    pool = {pool};
end
if isequal(length(pool),1)
    pool = pool(ones(ng, 1));
end

[uniq_pool, pl] = getcls(pool);
uniq_pool = lower(uniq_pool);
np = length(uniq_pool);
[~, annot_dict] = parse_poolinfo(info_file);
islm = false(ng, 1);
% lmps = cell(ng, 1);
b = {''};
lmps = b(ones(ng,1));
for ii=1:np
    pool_rev = lower(sprintf('%s:%s', uniq_pool{ii}, args.bset_revision));
    if annot_dict.isKey(pool_rev)
        chip_file = annot_dict(pool_rev).chip_file;
        if isfileexist(chip_file)
            chip = parse_tbl(chip_file, 'verbose', false);
        else
            error('%s not found', chip_file)
        end
        keep = setdiff(chip.pr_id, ignore_genes);
        m = list2dict(keep);
        for jj=1:ng;
            %         idx = pl==ii;
            tok = tokenize(ps{jj},' /// ');
            isk = m.isKey(tok);
            
            if any(isk)
                islm(jj) = 1;
                lmps{jj} = tok{isk};
            end
        end
    else
        error('Unknown pool %s', pool_rev)
    end
end

end

