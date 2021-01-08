function gmt = mkgmtstruct(entry, head, desc, varargin)
% MKGMTSTRUCT Create a GMT structure
% G = MKGMTSTRUCT(E, H, D) returns a structure given a cell array
% of set members E, a list of set identifiers H. The length of E
% must match that of H. D is an cell array of set
% descriptions, can be empty. The structure G has the following fields:
% 'head' : Set identifier specified in H
% 'desc' : Optional set description
% 'entry' : Cell array of set members
% 'len' : number of members in the set
% 
% Examples
% G = mkgmtstruct({{'a','b','c'},{'l','m'},{'z'}},...
%                 {'s1','s2', 's3'}, [])

pnames = {'--mkunique'};
dflts = {true};
descs = {'Make set entries unique'};
config = struct('name', pnames, 'default', dflts, 'help', descs);
opt = struct('prog', mfilename,...
             'desc', 'Create a GMT structure',...
             'undef_action', 'error');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

assert(iscell(entry), 'E must be a cell array');
assert(iscell(head), 'H must be a cell array');
assert(isvarexist('desc'), 'D must be defined');
assert(iscell(desc) || isempty(desc), 'D must be a cell or empty');

% Standardize to row arrays
entry = entry(:);
head = head(:);

% uniqueify the sets 
if args.mkunique
    entry = cellfun(@(x) unique(x, 'stable'), entry, 'unif', false);
end

% check dims
nset = length(entry);
nhead = length(head);
assert(isequal(nhead, nset), ['Size mismatch between H and ' ...
                    'E, expected %d got %d'], nset, nhead);
dup_head = duplicates(head);
disp(dup_head)
assert(isempty(dup_head), 'members of H must be unique');

% set sizes
len_cell = cellfun(@length, entry, 'unif', false);

% add desc if not defined
if isempty(desc)
    desc = cellfun(@(x) sprintf('%d', x), len_cell, 'unif', false);
else
    desc = desc(:);
    ndesc = length(desc);
    assert(isequal(ndesc, nset), ['Size mismatch between D and E, expected ' ...
                        '%d got %d'], nset, ndesc); 
end

gmt = struct('head', head,...
             'desc', desc,...
             'entry', entry,...
             'len', len_cell);

end
