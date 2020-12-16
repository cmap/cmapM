function header = parse_header(fname, varargin)
% PARSE_HEADER Read header fields of delimited file
% HD = PARSE_HEADER(FNAME) read tab or comma separated header fields
% % HD = PARSE_HEADER(FNAME, 'delimiter', C) read header 
% fields sepearated by character C 


config = struct('name', {'--delimiter'},...
    'default', {{'\t', ','}},...
    'help', {'value separator'});
opt = struct('prog', mfilename, 'desc', 'Read first line of delimited file');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


fid = fopen(fname, 'r');
first_line = fgetl(fid);
fclose(fid);
hd = textscan(first_line, '%s', 'delimiter', args.delimiter);
header = hd{1};

end