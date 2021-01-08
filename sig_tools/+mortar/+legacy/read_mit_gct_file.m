
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function D=read_mit_gct_file(fname)

gdesc={};
gacc={};
sdesc={};

%F=fread(fid);
%s=char(F');

if (0)
  fid=fopen(fname,'r');
  ln=1;
  while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    l{ln}=tline;
    ln=ln+1;
    if mod(ln,1000)==0
      disp(ln)
    end
  end
  fclose(fid);
  ln=ln-1;
  sd=dlmsep(l{3});
  tmp=sscanf(l{2},'%d\t%d');
  ngenes=tmp(1);
  nsamples=tmp(2);
else
  ln=line_count(fname);
  [l,fid]=read_dlm_file(fname,char(9),3);
  sd=l{3};
  ngenes=str2num(l{2}{1});
  nsamples=str2num(l{2}{2});
end

if ln<3
  error('GCT FILE must have at least 2 lines');
end

% skip line 1,2

% Description \t Accession Name1 \t \t Name2 \t \t Name\3 \t
if ~strcmp(lower(sd{1}),'name')
  error(['GCT FILE first element of the third row should be ' ...
         'Name']);
end
if ~strcmp(lower(sd{2}),'description')
  error(['GCT FILE second element of the third row should be ' ...
         'Description']);
end

sdesc=[];

for i=3:length(sd)
  sdesc=strvcat(sdesc,sd{i});
end

if ngenes+3 ~= ln
  error('GCT FILE inconsistent number of lines and genes');
end

if nsamples ~= size(sdesc,1)
  error('GCT FILE inconsistent number of rows and samples');
end

dat=zeros(ngenes,size(sdesc,1));

gdesc={};
gacc={};

if (0)
  for i=4:(ngenes+3)
    if mod(i,1000)==0
      disp(i)
    end
    la=dlmsep(l{i});
    gdesc{i-3}=la{2};
    gacc{i-3}=la{1};
    dat(i-3,:)=str2num(str2mat(la(3:1:end)))';
  end
else
  form=['%s%s' repmat('%f',1,nsamples) repmat('%*s',1,length(sd)-nsamples-2)];
  F=textscan(fid,form,'delimiter',char(9));
  gacc=F{1};
  gdesc=F{2};
  dat=cat(2,F{3:end});
end
fclose(fid);

D.gdesc=gdesc;
D.gacc=gacc;
D.sdesc=sdesc;
D.dat=dat;


