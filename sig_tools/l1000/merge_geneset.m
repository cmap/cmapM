function combods = merge_geneset(dsfile, varargin)
% MERGE_GENESET Combine genesets
% GSALL = MERGE_GENESET(GS1, GS2....)

if ~iscell(dsfile)
    error('Expected cell array as input');
end
nds = length(dsfile);
if ~isempty(dsfile{1})
    combods = parse_geneset(dsfile{1});
else
    combods = mkgmtstruct({}, {}, {});
end

for ii=2:nds
    if ~isempty(dsfile{ii})
        tmpds = parse_geneset(dsfile{ii});
    else
        tmpds = mkgmtstruct({}, {}, {});
    end    
    %dbg(1, '%d/%d\n', ii, nds);
    if ~isempty(tmpds)
        combods = merge_two(combods, tmpds);
    end
end

end

%%
function combods = merge_two(ds1, ds2)
% MERGE_TWO Combine two datasets

all_sets = [ds1; ds2];
set_id = {all_sets.head}';
nset = length(set_id);
[dups, idup, gdup, repcnt, dupcnt] = duplicates(set_id);
[~, no_dup] = setdiff(set_id, dups);
combods = all_sets(no_dup);
ndup = length(dups);
% merged sets are in the first rep
if ndup
    dbg(1, 'Merging %d sets', ndup);
end
keep_idx = idup(repcnt==1);
for ii=1:ndup
    this = idup(gdup==ii);
    nthis = length(this);
    for jj=2:nthis
        all_sets(this(1)).entry = union(all_sets(this(1)).entry,...
            all_sets(this(jj)).entry,'stable');
    end
    all_sets(this(1)).len = length(all_sets(this(1)).entry);
end
combods = [combods; all_sets(keep_idx)];
end
