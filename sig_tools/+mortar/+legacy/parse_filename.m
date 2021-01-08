% PARSE_FILENAME Parse and validate filenames from an input string
%   [FL, FC] = PARSE_FILENAME(S) parses the string S for valid files and
%   folder names, checks if each file exists and additionally searches for
%   files in each specified folder. FL is a cell array of files, FC is the
%   number of files.
%   [FL, FC] = PARSE_FILENAME(S,...) Specify optional parameter/value pairs.
%   'wc' specify wildcards. Comma separated string. Default is '*.*'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Oct.21.2010 17:01:45 EDT

function [fl, fc] = parse_filename(s, varargin)
import mortar.legacy.*
pnames = {'wc'};
dflts = {'*.*'};
arg = parse_args(pnames, dflts, varargin{:});
% wildcards
wc = tokenize(arg.wc, ',',true);

if iscellstr(s)
    f = s;
elseif ischar(s)
    % tokenize file string
    f = tokenize(s, ',', true);
else
    error('Invalid input')
end
nf = length(f);
fl = cell(nf,1);
fc = 0;
for ii=1:nf
    thisfile = mapdir(f{ii});
    % if its a folder add its contents
    if isfileexist(thisfile, 'dir')
        for jj=1:length(wc) 
            fpath = fullfile(thisfile, wc{jj});
            d = dir(fpath);
            x = {d.name}';
            if ~isempty(x)                
                p = fileparts(fpath);
                fl(fc + (1:length(x)),1) = strcat(p, filesep, x);
                fc = fc + length(x);               
            end
        end
    % check if file exists
    elseif isfileexist(thisfile, 'file')
        fc = fc + 1;
        fl{fc,1} = thisfile;
    else
        error('File %s not found', thisfile);
    end
end
% fix for empty list
fl = fl(1:fc);