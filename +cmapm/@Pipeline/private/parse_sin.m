% PARSE_SIN Parse a sin file
%   SIN = PARSE_SIN(SINFILE) Returns a sructure (SIN) with fieldnames set 
%   to header labels in row one of SINFILE.
%
%   SIN = PARSE_SIN(SINFILE, NOCHECK) Specifies if syntax checking is done
%   on the sin file. NOCHECK is true by default.
%
%   SIN = PARSE_SIN(SINFILE, NOCHECK, HASHEAD) Specifies if file has a
%   header row. HASHEAD is true by default.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT


function sins = parse_sin(sinfile, nocheck, varargin)

pnames = {'version','numhead','lowerhdr', 'detect_numeric','verbose','ignorehash'};
dflts = {'legacy', 1, false, true, false, true};
arg = parse_args(pnames, dflts, varargin{:});

if (exist('nocheck','var'))
    docheck = nocheck;
else
    docheck = 0;
end

% guess number of fields
% if the fieldnames have no spaces this should work
if arg.verbose
    fprintf ('Reading %s\n', sinfile);
end
first = textread(sinfile,'%s',1,'delimiter','\n','headerlines',max(arg.numhead-1,0));
if arg.numhead>0
    fn = strread(char(first),'%s', 'delimiter','\t');
else
    tmp = strread(char(first),'%s', 'delimiter','\t');
    fn = gen_labels(size(tmp,1) ,'prefix','COL');
end

%convert headers to lowercase
if arg.lowerhdr
    fn = lower(fn);
end

nf=length(fn);
if arg.ignorehash
    keep = find(~strncmp('#', fn, 1));
    nkeep = length(keep);
else
    keep = 1:nf;
    nkeep = nf;
end

% fix bad names
fn = validvar(fn,'_');

data=cell(nf,1);
fmt=repmat('%s',1,nf);
% no comments allowed
[data{:}]=textread (sinfile,fmt,'delimiter','\t','headerlines', max(arg.numhead,0), 'bufsize',50000);

% nrec = length(data{1});
for k=1:nkeep
    ii = keep(k);
    % Matlab bug , if last row(s) of last field is empty then data can be
    % less than nrec
    nrec0 = length(data{ii});
    %convert numeric fields to double
    if arg.detect_numeric
        
        isnum = all(~isnan(str2double(regexprep(data{ii}(randsample(nrec0, floor(nrec0/20)+1),:),'nan','0'))));
        if isnum
            data{ii}=str2double(data{ii});
        end
    end
    if isequal(arg.version,'legacy')
        sins.(fn{ii})=data{ii};
    elseif isequal(arg.version,'dict')
        if ii==1
            sins = mortar.data.dict;
        end
        if sins.isKey(fn{ii})
            error ('Duplicate key name found: %s', fn{ii});
        end
        sins(fn{ii}) = data{ii};
    else
        if arg.detect_numeric && isnum
            numcell = num2cell(data{ii});
            [sins(1:nrec0,1).(fn{ii})] = numcell{:};
        else
            [sins(1:nrec0,1).(fn{ii})] = data{ii}{:};
        end
    end
end

if (docheck)
    %check for syntax errors
    confess(sins);
end
