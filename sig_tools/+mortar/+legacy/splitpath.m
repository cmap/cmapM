
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function [h,t] = splitpath(p)

tok = tokenize(p, filesep);
isb = cellfun(@isempty,tok);
%last nonempty entry
last = find(~isb, 1, 'last');
%tail
t = [tok{last}];
% to remove
delme = print_dlm_line(tok(last:end),1,filesep);
%head
h = regexprep(p, [delme,'$'], '');
