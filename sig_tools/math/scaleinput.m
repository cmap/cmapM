% SCALEINPUT standardize input to [-1, +1]
% Y = SCALEINPUT(X) standardizes columns of X to range from -1 to +1

function [y, scfactor]  = scaleinput(x, scfactor)

if ~exist('scfactor', 'var')
    xmin = min(x);
    xmax = max(x);
    xmidrange = (xmin + xmax)/2;
    xrange = (xmax - xmin);
    if xrange < eps
        xrange = 0.5*ones(size(xrange));
    end
    scfactor = [xmin(:), xmax(:)];        
else
    xmidrange = 0.5*(scfactor(:,1) + scfactor(:,2))';
    xrange = (scfactor(:,2) - scfactor(:,1))';
end

% range [0,1]
%y = (x - repmat(min(x,[],1),size(x,1),1))*spdiags(1./(max(x,[],1)-min(x,[],1))',0,size(x,2),size(x,2));
% range [-1 1]
%y = (x - repmat(xmidrange, size(x,1), 1)) * spdiags(2./xrange', 0, size(x,2), size(x,2));
y = (x - repmat(xmidrange, size(x,1), 1)) .* repmat(2./xrange, size(x,1), 1);
