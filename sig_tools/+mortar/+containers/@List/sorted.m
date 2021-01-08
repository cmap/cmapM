function [srt, srtidx] = sorted(obj, direc)
% Return sorted list of elements. Does not modify the object.
% List.sorted
% List.sorted(DIREC) where DIREC is 'ascend' (default) or 'descend'.

if nargin == 1
    direc = 'ascend';
else
    direc = lower(direc);
end
assert (ismember(direc, {'ascend', 'descend'}), ...
    'Direc sould be ''ascend'' or ''descend''');
[srt, srtidx] = sort(obj.data_);
if isequal(direc, 'descend')
    srtidx = srtidx(end:-1:1);
    srt = obj.data_(srtidx);
end

end