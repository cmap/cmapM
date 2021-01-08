function [s, idup] = mkuniq_str(s)
% MKUNIQ_STR De-duplicate cell array of strings
% U = MKUNIQ_STR(S) finds duplicate entries in cell array S and appends a
% unique integer to deduplicate them

assert(iscell(s), 'Expected cell input');

idup = [];
if length(s)>1
    [dup, idup, ~, rdup] = duplicates(s);
    
    if ~isempty(dup)
        s(idup) = strcat(s(idup), '.', num2cellstr(rdup));
    end
end

end