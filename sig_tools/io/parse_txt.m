% PARSE_TXT Parse a GEO TXT file
%   SIN = PARSE_TXT(SINFILE) Returns a sructure (SIN) with fieldnames set 
%   to header labels in row one of SINFILE.
%
%   SIN = PARSE_SIN(SINFILE, USECOMMENTS) Specifies if lines starting with
%   a # are treated as comments. USECOMMENTS is true by default.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function sins = parse_txt(sinfile,usecomments)

if (exist('usecomments','var'))
    allowcomments = usecomments;
else
    allowcomments = 1;
end

% guess number of fields
% if the fieldnames have no spaces this should work

if allowcomments 
    first = textread(sinfile,'%s',1,'delimiter','\n','commentstyle','shell');
    fn = strread(char(first),'%s', 'delimiter','\t');
    fn = validvar(fn,'_');
    nf=length(fn);
    data=cell(nf,1);
    fmt=repmat('%s',1,nf);
    %comments=#
    [data{:}]=textread (sinfile,fmt,'delimiter','\t','commentstyle','shell','headerlines',2,'bufsize',50000);
else
    
    first = textread(sinfile,'%s',1,'delimiter','\n');
    fn = strread(char(first),'%s', 'delimiter','\t');
    fn = validvar(fn,'_');
    nf=length(fn);
    data=cell(nf,1);
    fmt=repmat('%s',1,nf);
    % no comments allowed
    [data{:}]=textread (sinfile,fmt,'delimiter','\t','headerlines',1,'bufsize',50000);
end

for ii=1:nf
    sins.(fn{ii})=data{ii};
end
