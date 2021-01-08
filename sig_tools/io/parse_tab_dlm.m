%PARSE_TAB_DLM Read a tab delimited data file
% [H,V] = PARSE_TAB_DLM(FNAME) Reads a tab-delimited file FNAME and returns
% the first row as a header ans the contents of each column as a cell array
% V.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [h,v] = parse_tab_dlm(fname)

try 
    fid = fopen(fname,'rt');
catch
    rethrow(lasterror);
end

%read header
%first line
l=fgetl(fid);
l = textscan(l,'%s');
h = l{1};
nf=length(h);


fmt=repmat('%s',1,nf);

%line count
% lc = linecount(fname) - 2;
%maxline = 4000;
maxbuf = 100000;
%iter=ceil(lc/maxline);
%lctr=0;
skip=1;
v=cell(nf,1);

[v{:}]=textread(fname,fmt,'delimiter','\t','bufsize',maxbuf,'headerlines',skip);


fclose(fid);




