function yhat = lr4pmodel(b0, logx)


[top, bot, logec50, hillc] = deal(b0(1), b0(2), b0(3), b0(4));
logx = logx(:);

% yhat=min+(max-min)./(1+(x1/ec).^hillc);
%ec50 model
% yhat = real(top + (top - bot)./(1+(ec50./x).^hillc));

yhat = bot + (top - bot) ./ (1+10.^((logec50 - logx)*hillc));
%logec50 model