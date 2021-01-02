% MKCLS Creates a class format file in GSEA .cls format
% mkcls(cl,outfile)
% INPUTS:
% cl        : cell array of class labels for each sample
% outfile   : output filename
% See Also: GETCLS, PARSE_CLS

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function mkcls(cl, outfile, uselabels)

[cn, nl]= getcls(cl);

if ~exist('uselabels','var')
    uselabels = false;
end

%fix spaces
cn=strrep(cn,' ','_');

nsamp = length(cl);
nclass = length(cn);
fid=fopen(outfile,'wt');

% line 1 
fprintf (fid,'%d %d 1\n# ',nsamp,nclass);

% line 2 user-visible name for each class
for ii=1:nclass
    fprintf (fid,'%s ',cn{ii});
end

fprintf (fid, '\n');

% line 3 class labels for each sample
% class labels range [0 to nclass-1]
if ~uselabels
    fprintf (fid,'%d ',nl-1);
    fprintf (fid,'\n');
else
    print_dlm_line(cn(nl),fid,' ');
end

fclose(fid);
