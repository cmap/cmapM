
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:47 EDT
function [pc, ps] = wvclassify(mind , wt, mu1,mu2, x)

%total votes
vtot = length(mind);

%decision boundaries
b=(mu1+mu2)*0.5;

%cast votes
%%unweighted votes
uv = (x(mind)-b);
v = uv.*wt;


%predicted class (class1= 1 class2= -1
pc=sign(sum(v));

%tally winning and losing votes
%vwin = sum(sign(v)==pc);
vwin = sum(sign(uv)~=pc);
vlose = vtot-vwin;

%prediction strength
ps = abs((vwin-vlose)/vtot);

%recode predicted class so that class1=1 class2=2
pc = 1 + (pc<0);
