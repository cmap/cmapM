function combodict = merge_celldict(d, varargin)
% MERGE_CELLDICT Merge a collection array of cell array dictionaries
%   COMBODICT = MERGE_CELLDICT(D) returns a combined dictionary COMBODICT
%   given a cell array of dictionaries D. The keys in COMBODICT are the
%   union of all keys in D and the values for each key is a cell array of
%   length equal to length(D).
%
%   COMBODICT = MERGE_CELLDICT(D, 'has_scalar_value', true) merges a set of
%   dictionaries where each key maps to a single scalar value. Default of
%   has_scalar_value is false.

pnames = {'has_scalar_value'};
dflts = {false};
arg = parse_args(pnames, dflts, varargin{:});
switch(class(d))
    case 'containers.Map'
        combodict = d;
    case 'cell'
        nd = length(d);
        allkeys = {};
        combodict = containers.Map();
        for ii=1:nd
           allkeys = union(allkeys, d{ii}.keys);
        end
        nkeys = length(allkeys);
        keyidx = containers.Map(allkeys, 1:nkeys);
        
        % scalar value dictionary
        % d dictionaries, i-th dictionary has k_i keys, each maps to a
        % single value
        % output: single dictionary with union(k_i) keys, each maps to a
        % cell array of length(d)
        if arg.has_scalar_value
            vals = cell(nd, nkeys);
            for ii=1:nd
                k = d{ii}.keys;
                idx = arrayfun(@(x) x{:},keyidx.values(k));
                vals(ii, idx) = d{ii}.values;
            end
            
            for ii=1:nkeys
                combodict(allkeys{ii}) = vals(:,ii);
            end
        else
            % d dictionaries, i-th dictionary has k_i keys,
            % each maps to a cell array of length n_i
            % output: single dictionary with union(k_i) keys, each mapping to a
            % cell array of length sum(n_i)
            
            for ii=1:nd
                k = d{ii}.keys;
                for jj=1:length(k)
                    if combodict.isKey(k{jj})
                        try
                        combodict(k{jj}) = [combodict(k{jj}); d{ii}(k{jj})];
                        catch
                            keyboard
                        end
                    else
                        combodict(k{jj}) = d{ii}(k{jj});
                    end
                end
            end
            
        end
        
        
    otherwise
        error('Input should be a cell array of dictionaries')
end