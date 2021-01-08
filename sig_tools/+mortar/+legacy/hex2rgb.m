function rgb = hex2rgb(s)
% Convert hex str to matlab color

% valid hex string
s = strrep(s, '#','');
assert( isequal(length(s), 6) && ischar(s), ...
    'Invalid input')

rgb = hex2dec(reshape(s(1:end),2,3)');

end