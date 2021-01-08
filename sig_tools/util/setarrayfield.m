function s = setarrayfield(s, sidx, fn, varargin)
% SET_STRUCT_ARRAY_FIELD Assign field to a struct array
%   S = SET_STRUCT_ARRAY_FIELD(S, SIDX, FN, VAL1, VAL2, ...)
% Upserts fields FN of structure S with values VAL1, VAL2... for indices of
% S specified by SIDX. If SIDX is empty all the values are updated and
% assumed to be ordered the same as S. If SIDX is non-empty only those
% indices specified by SIDX are upserted.
%
% Example
% s = struct('id', num2cell(1:10)', 'val1', cellstr(char(65:74)'));
% val2 = linspace(0,1,10);
% val3 = cellstr(char(97:106)');
% s = setarrayfield(s, [], {'val2', 'val3'}, val2, val3); 
% % Update specific indices
% val4 = rand(5,1);
% s = setarrayfield(s, 6:10, 'val4', val4); 

if ~iscell(fn)
    assert(ischar(fn), 'fn should be a string or cell array');
    fn ={fn};
end
if isempty(sidx)
    sidx = 1:length(s);
end

nf = length(fn);
nval = nargin - 3;
assert(isequal(nf, nval),...
    'Number of value must match fields. Expected %d got %d', nf, nval);

for ii = 1:nf
    val = varargin{ii};
    if isnumeric(val) || islogical(val) 
        val = num2cell(val);
    end
    if ischar(val)
        val = {val};
    end
    if isscalar(val)
        [s(sidx).(fn{ii})] = deal(val{:});
    else
        [s(sidx).(fn{ii})] = val{:};
    end
end

end