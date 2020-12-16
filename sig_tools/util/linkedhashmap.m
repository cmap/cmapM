function hash = linkedhashmap(key, value, varargin)
%HASHMAP create a java hashmap of keys and values.
%   H = HASHMAP() Constructs an empty HashMap with the default initial
%   capacity (16) and the default load factor (0.75).
%
%   H = HASHMAP(KEY, VALUE) Constructs a new HashMap with the key/value mappings
%   as the specified by KEY and VALUE. MAP is a 1x2 cell array with the first column
%   containing a vector or cell array of keys and the second column a
%   vector or cell array of values.
%
%   H = HASHMAP('param', value) Specifies parameters of the hashmap.
%
%   Parameters:
%       initial_capacity: the number of buckets in the hash 
%                        table at the time the hash table is created. The
%                        default is 16
%       load_factor: is a measure of how full the hash table is allowed to
%                   get before its capacity is automatically increased. The
%                   default is 0.75
%
%   This implementation utilizes the java HashMap. For details see:    
%   http://java.sun.com/j2se/1.4.2/docs/api/java/util/HashMap.html
%   Example:
%       hash = hashmap({'foo','bar','abc'}, 1:3);
%       hash.get('bar')     % returns 2
%       hash.put('xyz',4)   % adds a new mapping 
%       cell(hash.keySet.toArray)         % lists all keys


% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

pnames = {'initial_capacity', 'load_factor'};
dflts = {16, 0.75};

if ~isvarexist('key')
    key = {};
end
if ~isvarexist('value')
    value = {};
end
nk = length(key);
assert(isequal(nk, length(value)), 'Number of keys should match the number of values');

args = parse_args(pnames, dflts, varargin{:});

% create hash            
hash = java.util.LinkedHashMap(args.initial_capacity, args.load_factor);

% add mappings
iskeycell = iscell(key);
isvalcell = iscell(value);

for ii=1:nk
    if iskeycell
        k=key{ii};
    else
        k=key(ii);
    end
    
    if isvalcell
        v=value{ii};
    else
        v=value(ii);
    end
    
    hash.put(k, v);
end

