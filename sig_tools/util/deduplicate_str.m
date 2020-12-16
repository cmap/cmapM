function s = deduplicate_str(s, varargin)
% DEDUPLICATE_STR Replace duplicates in cell array with unique values.
% T = DEDUPLICATE_STR(S) checks for duplicate values in a cell string array
% S and replaces duplicates with an integer to make them unique.
%
% Examples
% deduplicate_str({'a','b','a', 'c', 'b'})
pnames = {'--verbose'};
dflts = {true};
help_str = {'Print verbose messages'};
config = struct('name', pnames,...
                  'default', dflts,...
                  'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Replace duplicates in cell array with unique values');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

s = s(:);
[dup, idup, gdup, rdup] = duplicates(s);

if ~isempty(dup)
    dbg(args.verbose, 'Duplicate values found for %d entries, making them unique', length(dup));
    if args.verbose
        disp(dup)
    end
is_dup = rdup>1;
dup_idx = idup(is_dup);
dup_val = num2cellstr(rdup(is_dup)-1);

s(dup_idx) = paste([s(dup_idx), dup_val], '_');

end