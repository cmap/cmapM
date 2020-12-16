function [xc, yc] =randring(m,c,r1,r2)

nin = nargin;
if nin==0
    c=[0, 0];
    r1=0.5;
    r2=r1;
    m=1;
elseif nin==1
    r1=0.5;
    r2=r1;
    c=[0 0];    
elseif nin==2
    r1=0.5;
    r2=r1;
elseif nin==3
    r2=r1;
end

xc = 2*r2*(rand(m,1)-0.5);
yc = 2*r2*(rand(m,1)-0.5);
ic = check_inring(xc,yc,r1,r2);
nok = nnz(ic);
remain = m-nok;
xc(1:nok) = xc(ic)+c(1);
yc(1:nok) = yc(ic)+c(2);

while remain>0
    x = 2*r2*(rand(m,1)-0.5);
    y = 2*r2*(rand(m,1)-0.5);
    ic = check_inring(x,y,r1,r2);
    n = nnz(ic);
    if n
    nkeep = min(remain,n);
    xc(nok+(1:nkeep)) = x(find(ic, nkeep))+c(1);
    yc(nok+(1:nkeep)) = y(find(ic, nkeep))+c(2);
    remain = remain-n;
    end
end

end

function ic = check_inring(xc, yc, r1, r2)
ic = (xc.^2 + yc.^2 < r2^2) & (xc.^2 + yc.^2 > r1^2);
end