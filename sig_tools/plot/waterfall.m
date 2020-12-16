
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:47 EDT
function h = waterfall(x,y)

nin=nargin;

nargchk(1,2 ,nin);

if (nin ==1)
    y=x;
    x=1:length(y);
end

csm = cumsum(y);

y1=cumsum(y)-y; 
y1(end)=0;

y2=y; 
y2(end)=csm(end);

figure;
h = bar(x, [y1;y2]','stack');
set (h(1), 'FaceColor','none', 'EdgeColor', 'none');
