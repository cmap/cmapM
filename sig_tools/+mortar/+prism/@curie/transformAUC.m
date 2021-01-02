function ds_auc = transformAUC(ds_auc, transform)
% transformAUC Transform AUC dataset

valid_transform = {'sqrt', 'arcsin', 'asin', 'log2'};
assert(isvalidstr(transform, valid_transform));

switch(transform)
    case 'sqrt'
        ds_auc.mat = sqrt(ds_auc.mat + eps);
    case {'arcsin', 'asin'} 
        ds_auc.mat = asin(sqrt(ds_auc.mat + eps));
    case 'log2'
        ds_auc.mat = clip(log2(ds_auc.mat + eps), -15, inf);
    otherwise
        error('Unknown transform %s', transform)
end

end