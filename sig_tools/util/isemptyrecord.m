function tf = isemptyrecord(rec)
%tf = isemptystruct(struct)
%
% Return logical for if any row in a struct is empty
%
%Input
%       tbl: structure array, record
%
%Output
%       tf: logical, true if struct row is empty

    assert(isstruct(rec), 'Input must be a struct');

    fn = fieldnames(rec);

    nrows = numel(rec);
    
    tf = false(nrows, 1);
    for row = 1:numel(rec)
        for fld = 1:numel(fn)
            tf(row) = tf(row) | isempty(rec(row).(fn{fld}));
        end
    end
end