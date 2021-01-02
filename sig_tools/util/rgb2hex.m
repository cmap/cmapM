function hex = rgb2hex(rgb)
% Convert RGB values to hex.
% HEX = RGB2HEX(RGB) RGB is a nx3 matrix of RGB values [0,255]

if all(rgb(:)<=1)
    rgb = round(rgb*255);
end

hex = cellstr(reshape(dec2hex(rgb')', 6, size(rgb, 1))');

end