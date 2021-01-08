function parseFile_(obj, tblfile, varargin)
% PARSE_TBL Read a text table.
%   TBL = PARSE_TBL(TBLFILE) Returns a structure TBL with fieldnames set 
%   to header labels in row one of the table.
%
%   TBL = PARSE_TBL(TBLFILE, param1, value1,...) Specifies optional
%   parameters and values. Valid parameters are:
%
%   'outfmt' <String> Output format. Valid options are
%       {'column','record','dict'}. Default is 'column'
%
%   'numhead' <Integer> Number of lines to skip. Specifies the row
%   	where the data begins. Assumes the fieldnames are at
%   	(numhead-1)th row. Default is 1. 
%
%   'lowerhdr' <boolean> Convert header to lowercase. Default is True.
%
%   'detect_numeric' <boolean> Convert numeric fields to
%   	double. Default is True. 
%
%   'ignore_hash' <boolean> Ignore fields that begin with a
%   	hash. Default is True.
%
%   'comment_style' <String> Symbol(s) designating lines to ignore. Specify
%       a single string (such as '%') to ignore characters following the
%       string on the same line. Specify a cell array of two strings (such
%       as {'/*', '*/'}) to ignore characters between the strings. Default
%       is '#'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'--outfmt', '--numhead', '--lowerhdr', ...
    '--detect_numeric', '--ignore_hash', '--verbose',...
    '--ignore_type', '--comment_style'};
dflts = {'column', 1, true, ...
    true, true, true,...
    '', '#'};
s = struct('name', pnames, 'default', dflts);
p = mortar.common.ArgParse(mfilename);
p.add(s);
args = p.parse(varargin{:});

assert(isfileexist(tblfile), 'File not found');

% guess number of fields
% if the fieldnames have no spaces this should work

fid = fopen(tblfile, 'r');
first = textscan(fid, '%s', 1, ...
'delimiter', '\n', 'headerlines', ...
 max(args.numhead-1, 0), 'commentstyle', args.comment_style);
if args.numhead>0
    fn = textscan(char(first{1}), '%s', 'delimiter', '\t');
    fn = fn{1};        
%     dup = fn.duplicates;
%     if ~isempty(dup)
%         warning('PARSE_TBL:duplicateHeaders',...
%             'Header has duplicate fields, keeping the one(s) that occur(s) last');
%         disp(dup);
%     end
else
    tmp = textscan(char(first{1}), '%s', 'delimiter', '\t');    
    fn = mortar.common.Util.genLabels(length(tmp{1}), ...
        '--zeropad', false, '--prefix', prefix);
    % rewind to beginning
    fseek(fid, 0, 'bof');
end

% convert headers to lowercase
if args.lowerhdr
    fn = lower(fn);
end

nf = length(fn);
% ignore fields that begin with a hash
if args.ignore_hash
    keep = find(~strncmp('#', fn, 1));
else
    keep = 1:nf;
end
nc = length(keep);

% fix bad names
fn = mortar.common.Util.validateVar(fn, '_');

fmt = repmat('%s', 1, nf);

obj.col_ = mortar.containers.Dict(fn);
data = textscan(fid, fmt, 'Delimiter', '\t');

fclose (fid);
% ignored commented lines
% note commentstyle in textscan checks all fields not just the first one.
keep_lines = ~strncmp(data{keep(1)}, args.comment_style,...
                length(args.comment_style));
nr = length(keep_lines);

obj.data_ = cell(nr, nc);

for k=1:nc
    ii = keep(k);
     obj.data_(:, ii) = data{ii}(keep_lines);     
    % convert numeric fields to double
    if args.detect_numeric && ~ismember(fn(ii), args.ignore_type)   
        [obj.data_(:, ii), isnum] = mortar.common.Util.detect_numeric(obj.data_(:, ii));        
%         if isnum
%             % convert cell array  to vector for these formats
%             obj.data_{ii} = cell2mat(obj.data_{ii});
%         end
    end

end

obj.row_ = obj.genLabel_(nr, true);
