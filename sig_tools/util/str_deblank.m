function s = str_deblank(s, tail)
% STR_DEBLANK Remove white space
%   D = STR_DEBLANK(S)
%   D = STR_DEBLANK(S, TAIL) specify the end where the deblanking is
%   performed. TAIL can be {'both', 'leading', 'trailing'}. The default is
%   'both'

if ischar(s)
    was_char = true;
    s = {s};
else
    was_char = false;
end
    
if ~isvarexist('tail')
    tail = 'both';
end
    
tail = lower(tail);

switch lower(tail)
    case 'both'
        s = deblank(cellfun(@fliplr, deblank(cellfun(@fliplr, s,'unif',false)), 'unif', false));
    case 'leading'
        s = cellfun(@fliplr, deblank(cellfun(@fliplr, s,'unif',false)), 'unif', false);
    case 'trailing'
        s = deblank(s);
    otherwise
        error('Expected tail to be {both, leading, trailing}, got %s', tail);
end
if was_char
    s = s{1};
end    

end
