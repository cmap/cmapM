function c = hex2color(s)
% Convert hex str to matlab color

% valid hex string
s = strrep(s, '#','');
assert( isequal(length(s), 6) && ischar(s), ...
    'Invalid input')

c = hex2rgb(s) / 255;

end