function auc = AUC(x,y)
% Have enough data?
if length(x)<2
    auc = 0;
    return;
end

if any(x < 0)
    ix = x< 0; 
    x(ix) = 0; 
end

% Get area
auc = 0.5*sum( (x(2:end)-x(1:end-1)).*(y(2:end)+y(1:end-1)) );
auc = abs(auc);
end