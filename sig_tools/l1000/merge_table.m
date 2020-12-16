function [combotbl, missfields] = merge_table(dsfile, varargin)
% MERGE_TABLE Append multiple tables.

pnames = {'missval'};
dflts = {'-666'};
args = parse_args(pnames, dflts, varargin{:});
[combotbl, missfields] = parse_sin_multi(dsfile, args.missval);
end

function [tbl, missfields] = parse_sin_multi(dsfile, missval)
nd = length(dsfile);
%tbl = parse_sin(dsfile{1}, 0, 'detect_numeric', false, 'lowerhdr', true);
tbl = parse_tbl(dsfile{1}, 'detect_numeric', false, 'lowerhdr', true);
fn = fieldnames(tbl);
rowctr = length(tbl.(fn{1}));
missfields = [];
for ii=2:nd
%     x = parse_sin(dsfile{ii}, 0, 'detect_numeric', false, 'lowerhdr', true);
    x = parse_tbl(dsfile{ii}, 'detect_numeric', false, 'lowerhdr', true);
    newfn = fieldnames(x);
    nrow = length(x.(newfn{1}));
    for jj=1:length(newfn)
        if any(strcmp(newfn{jj}, fn))
            tbl.(newfn{jj})(rowctr+(1:nrow),:) = x.(newfn{jj});
        else
            tbl.(newfn{jj}) = cell(nrow+rowctr, 1);
            tbl.(newfn{jj})(1:rowctr) = {missval};
            tbl.(newfn{jj})(rowctr+(1:nrow)) = x.(newfn{jj});
            missfields = union(missfields, newfn{jj});
        end
    end
    missing = setdiff(fn, newfn);
    for jj=1:length(missing)
        tbl.(missing{jj})(rowctr+(1:nrow)) = {missval};
    end
    missfields = union(missfields, missing);
    fn = union(fn , newfn);
    rowctr = rowctr + nrow;
end

end