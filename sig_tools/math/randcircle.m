function [xc, yc] =randcircle(m,c,r)

nin = nargin;
if nin==0
    c=[0, 0];
    r=0.5;
    m=1;
elseif nin==1
    r=0.5;
    c=[0 0];    
elseif nin==2
    r=0.5;
end

xc = 2*r*(rand(m,1)-0.5);
yc = 2*r*(rand(m,1)-0.5);
ic = check_incircle(xc,yc,r);
nok = nnz(ic);
remain = m-nok;
xc(1:nok) = xc(ic)+c(1);
yc(1:nok) = yc(ic)+c(2);

while remain>0
    x = 2*r*(rand(m,1)-0.5);
    y = 2*r*(rand(m,1)-0.5);
    ic = check_incircle(x,y,r);
    n = nnz(ic);
    if n
    nkeep = min(remain,n);
    xc(nok+(1:nkeep)) = x(find(ic, nkeep))+c(1);
    yc(nok+(1:nkeep)) = y(find(ic, nkeep))+c(2);
    remain = remain-n;
    end
end

end

function ic = check_incircle(xc, yc, r)
ic = xc.^2 + yc.^2 < r^2;
end