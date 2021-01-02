
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function t = mytextwrap(s,width)

y=textwrap(s,width);

t='';
for ii=1:length(y)
    if ~isequal(ii,length(y))
        t = [t,sprintf('%s\n',y{ii})];
    else
        t = [t,sprintf('%s',y{ii})];
    end
end
