function s = meta2struct(ds, varargin)
% META2STRUCT Extract row or column annotations from a GCT struct
%   S = META2STRUCT(DS) returns column annotations along with an id
%   field for the column identifiers.
%   S = META2STRUCT(DS, DIM) returns row annotations if DIM is 2 or 'row'
%   and returns the column annotations if DIM is 1 or 'column'

nin = nargin;
if isequal(nin, 1)
    dim = 1;
else
    dim = varargin{2};
end

switch (dim)
    case {1, 'column'}
        s = cell2struct([ds.cid, ds.cdesc], ['id'; ds.chd], 2);

    case {2,'row'}
        s = cell2struct([ds.rid, ds.rdesc], ['id'; ds.rhd], 2);
    otherwise
        error('Unknown dimension: %s', dim);
end

end
