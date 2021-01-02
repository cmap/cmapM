function b0 = lr4p_init(logx, y)

%top
b0(1) = max(y);
%bot
b0(2) = min(y);



% fit linreg model
Y = log10((b0(1) - y)./(y-b0(2)));
idx = ~isnan(Y) & ~isinf(Y) & Y~=0;
%if nnz(idx)>2
if false
    p = regress(Y(idx), x2fx(logx(idx)));
    %hill slope
    b0(4) = p(2);
    %logec50
    b0(3) = -p(1)/b0(4);
else
  % % fit linreg model
  p = regress(y(:), x2fx(logx));  
  %logec50
  midy = b0(2) + (b0(1) - b0(2))*0.5;
  b0(3) = (midy - p(1))/p(2);  
  %hill slope.
  b0(4) = p(2);
end