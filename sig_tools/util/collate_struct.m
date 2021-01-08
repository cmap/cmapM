function c = collate_struct(varargin)

% Start with collecting fieldnames, checking implicitly
% that inputs are structures.

assert(all(cellfun(@isstruct, varargin)), 'Inputs are not all structs');
fn = cellfun(@fieldnames, varargin, 'UniformOutput', false);
uniq_fn = unique(cat(1, fn{:}), 'stable');

% Now concatenate the data from each struct.  Can't use
% structfun since input structs may not be scalar.
%dbg(1, 'mergestruct:  concatenate data from each struct');
c = [];
for ii = 1:nargin
    try
        c = [c; keepfield(varargin{ii}, uniq_fn)];                
    catch MEdata
        throw(MEdata);
    end
end

end