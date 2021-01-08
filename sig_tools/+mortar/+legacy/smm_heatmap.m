function smm_heatmap(x)
% SMM_HEATMAP Image view of smm data
% 
%   smm_heatmap(x) will show an image of the smm data. The data is zscored
%   along the rows. 
%   Input: 
%       x - either LSS, s2n, or other smm data
%   Output:
%       An image is created in the current available window. 
% 
% see also imagesc, zscore
% 
% Author: Brian Geier, Broad 2010

imagesc(zscore(x')')
colormap jet
colorbar
