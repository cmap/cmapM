function [tile_dict, scale_dict, use_fixed_tile] = get_tile_map(varargin)
% GET_TILE_MAP Get optimal page layout and scaling for a given set of
% images.
% [tile_dict, scale_dict, use_fixed_tile] = get_tile_map(arg.tile)

pnames = {'tile', 'showfooter', 'showcaption'};
dflts = {'', true, true};
arg = parse_args(pnames, dflts, varargin{:});

% number of images per page
num_images = {1, 2, 3, 4, 5:6, ...
    7:8, 9, 10:12, 13:15, ...
    16:20, 21:24, 25, 26:30, ...
    31:35, 36, 37:42, 43:48};

% optimal layout of images
tile_setting = {'1x1', '1x2', '1x3', '2x2', '2x3', ...
    '2x4', '3x3', '3x4', '3x5', ...
    '4x5', '4x6', '5x5', '5x6', ...
    '5x7', '6x6', '6x7', '6x8'};
% num_image -> tile map
tile_dict = containers.Map('keytype', 'double', 'valuetype', 'char');
for ii=1:length(num_images)
    v = num_images{ii};
    for jj=1:length(v)
        tile_dict(v(jj)) = tile_setting{ii};
    end 
end

% optimal Latex scaling for each tile
scale_dict = containers.Map({'1x1', '1x2', '1x3', '2x2', '2x3', ...
    '2x4', '3x3', '3x4', '3x5', ...
    '4x5', '4x6', '5x5', '5x6', ...
    '5x7', '6x6', '6x7', '6x8'}, ...
    {0.88, 0.47, 0.3, 0.40, 0.3, ...
    0.22, 0.3, 0.22, 0.18,...
    0.20, 0.167, 0.20, 0.167,...
    0.143, 0.167, 0.143, 0.125...
    });

%adjust scale to allow for footers and captions
if arg.showfooter && arg.showcaption
    scale = 0.88;
elseif arg.showfooter
    scale = 0.95;
elseif arg.showcaption
    scale = 0.90;
else
    scale = 1.0;
end
if arg.showfooter || arg.showcaption
    keys = scale_dict.keys;
    for k = 1:length(keys)
        scale_dict(keys{k}) = scale_dict(keys{k}) * scale;
    end
end

use_fixed_tile = false;
if ~isempty(arg.tile)
    if isempty(strfind(arg.tile, ':'))
        use_fixed_tile = true;
        if ~scale_dict.isKey(arg.tile)
            dim = textscan(arg.tile, '%fx%f');
            scale_dict(arg.tile) = 0.80/dim{2};
        end
    else
        cust_tile = tokenize(arg.tile, ',');
        for ii=1:length(cust_tile)
            t = tokenize(cust_tile{ii}, ':');
            if ~isempty(strfind(t{2}, 'x'))
                if scale_dict.isKey(t{2})
                    tile_dict(str2double(t{1})) = t{2};
                else
                    dim = textscan(t{2}, '%fx%f');
                    tile_dict(dim{1}*dim{2}) = t{2};
                    scale_dict(t{2}) = 0.80/dim{2};
                end
            else
                scale_dict(tile_dict(str2double(t{1}))) = str2double(t{2});
            end
        end
    end
end