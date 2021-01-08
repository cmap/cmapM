% PARSE_LXB Parse an LXB (text) file
%   LXB = PARSE_LXB(LXBFILE) Returns a sructure (LXB) with fieldnames set 
%   to header labels in row one of LXBFILE.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT


function sins = parse_lxbtxt(lxbfile)

% guess number of fields
% if the fieldnames have no spaces this should work

first = textread(lxbfile,'%s',1,'delimiter','\n');

fn = strread(char(first),'%s', 'delimiter','\t');
fn = validvar(fn,'_');

nf=length(fn);
data=cell(nf,1);
fmt=repmat('%d',1,nf);
% no comments allowed
[data{:}]=textread (lxbfile,fmt,'delimiter','\t','headerlines', 1, 'bufsize',50000);

for ii=1:nf
    sins.(fn{ii})=data{ii};
end
