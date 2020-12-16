function newimg = resize_image(img, scale, varargin)

pnames = {'out', 'outfmt'};
dflts = {'', 'png'};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(img)
    img = imread(img);
elseif isnumeric(img)
    error('img should be a filename or a numeric array');
end

switch(ndims(scale))
    case {1,2}
        newimg = imresize(img, scale);        
    otherwise
        error('scale should be a scalar or 2 dimensional array')
end

if ~isempty(args.out)
    imwrite(newimg, args.out, args.outfmt)
end

end