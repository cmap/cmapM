function tf = rematch(s, pat, varargin)
% REMATCH Regular expression match on cell arrays
% TF = REMATCH(S, PAT) tests if cell-array of strings S matches the 
% regular-expression pattern specified by PAT. Returns a boolean array of
% length(S). An element i in TF is true if S{i} matches PAT.
if ischar(s)
    s = {s};
end

tf = ~cellfun(@isempty, regexp(s, pat, varargin{:}));

end