function ds = ds_make_symmetric(ds, symfun, nanval)
% DS_MAKE_SYMMETRIC Symmetricize a square matrix
% DS_MAKE_SYMMETRIC(DS, SYMFUN, NANVAL) returns a symmetric matrix from
% values in dataset DS by appyling the operation SYMFUN. NaN values in the
% output matrix are set to NANVAL. Valid values for SYMFUN are {'mean',
% 'max', 'min', 'absmax', 'absmin'}. 


ds.mat = make_symmetric(ds.mat, symfun, nanval);
% [nr, nc] = size(ds.mat);
% assert(isequal(nr, nc), 'Matrix should have the same rows and columns');
% 
% [ir, ic] = find(isnan(ds.mat));
% ds.mat(sub2ind(size(ds.mat), ir, ic)) = ds.mat(sub2ind(size(ds.mat), ic, ir));
% 
% switch(symfun)
%     case 'mean'
%         ds.mat = 0.5*(ds.mat + ds.mat');
%     case 'max'
%         ds.mat = max(ds.mat, ds.mat');
%     case 'min'
%         ds.mat = min(ds.mat, ds.mat');
% end
% ds = ds_nan_to_val(ds, nanval);

end