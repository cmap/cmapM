function [srt, srtidx] = sort(obj, varargin)
% Sort the elements in the list.
% [SRT, SRTIDX] = List.sort
% [SRT, SRTIDX] = List.sort(DIREC)
%
%  See also sorted

[srt, srtidx] = obj.sorted(varargin{:});
obj.data_ = srt;

end