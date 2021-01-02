function gmx = parse_gmx(fname)
%PARSE_GMX Read .gmx Gene matrix data format
% GMX = PARSE_GMX(FNAME) Reads .gmx file FNAME and returns the structure
% GMX. GMX is a nested structure GMX(1...NCOLS), where NCOLS is the number
% of columns in the GMX file. Each structure has the following fields:
%   head: column header, 1st row of the gmx file desc: column description,
%   2nd row of the gmx file len: length of column entry: cell array of
%   column entries
% 
% Format Details: The GMX file format is a tab demilited file format that
% describes gene sets. Each column represents a gene set.
%
% The first line contains geneset names. Duplicates are not allowed
% 
% The second line contains a brief description (can be filled with dummy
% names).
% 
% Each column represents one gene set. Unequal lengths (i.e. # of genes)
% are allowed. CAVEAT: this code does not handle missing values

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% 3/6/2008, returns nested structure instead of variables

try 
    fid = fopen(fname,'rt');
catch
    rethrow(lasterror);
end

%read gene set names
%first line
l=fgetl(fid);
l = textscan(l,'%s','delimiter','\t');
l=l{1};

nf=length(l);
gmx = struct('head',[],'desc',[],'len',[],'entry',[]);
[gmx(1:nf).head] = l{:};

%second line
l=fgetl(fid);
l=textscan(l,'%s','delimiter','\t');
l=l{1};

[gmx(:).desc] = l{:};

fmt=repmat('%s',1,nf);

%line count
% lc = linecount(fname) - 2;
%maxline = 4000;
maxbuf = 100000;
%iter=ceil(lc/maxline);
%lctr=0;
skip=2;
x=cell(1,nf);

[x{:}]=textread(fname,fmt,'delimiter','\t','headerlines',skip);


% gs=cell(nf,1);
% gslen = ones(nf,1)*size(x{1},1);
for ii=1:nf
    %last non blank idx
    idx = min(strmatch('',x{ii},'exact'))-1;
    if ~isempty(idx)
        gmx(ii).entry = x{ii}(1:idx);
        gmx(ii).len = idx;
    else
        gmx(ii).entry = x{ii};
        gmx(ii).len = length(gmx(ii).entry);
    end
end


fclose(fid);




