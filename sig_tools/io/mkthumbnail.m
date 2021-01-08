function mkthumbnail(imgpath, outpath, varargin)

pnames = {'scale', 'outfmt'};
dflts = {[nan, 128], 'png'};
args = parse_args(pnames, dflts, varargin{:});

filetypes = {'*.png','*.jpg','*.jpeg'};

% [p,f,e] = fileparts(imgpath);

[~, imlist] = find_file(imgpath);
nim = length(imlist);
if ~isdirexist(outpath)
    mkdir(outpath)
end

for ii=1:nim
    [~, f] = fileparts(imlist{ii});
    outfile = fullfile(outpath, sprintf('th_%s.%s', f, args.outfmt));
    resize_image(imlist{ii}, args.scale, 'out', outfile, 'outfmt', args.outfmt);
end

end