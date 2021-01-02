
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function mkheatmapper(cc, vname, fname)

[nr,nc]= size(cc);

%nr == nc

fid = fopen(fname,'wt');

print_dlm_line({'Variables',vname{:}},fid,',');

for ii=1:nr
    fprintf(fid, '%s,%s\n',vname{ii},sprintf('%f,',cc(ii,:)));
end

fclose(fid);
