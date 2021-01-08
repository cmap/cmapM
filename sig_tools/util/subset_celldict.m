function subd = subset_celldict(d, idx)
% SUBSET_CELLDICT extract a subset of well indices from a dictionary of
% cell arrays
% SUBD = SUBSET_CELLDICT(D, IDX) returns a dictionary of the indices IDX

switch class(d)
    case 'containers.Map'        
        keys = d.keys;
        subd = containers.Map();
        for ii=1:length(keys)
            vals = d(keys{ii});
            subd(keys{ii}) = vals(idx);
        end
        
    otherwise
        error('Input should be a dictionary')
end