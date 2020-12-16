function [him, hcb, axim] = imagescnan(a, cm, nanclr, rangeclr)
% IMAGESCNAN: IMAGESC with NaNs assigned a specified color
%     [H, HCB] = IMAGESCNAN(A, CM, NANCLR, RANGECLR)

% Adapted from:
% http://stackoverflow.com/questions/8481324/contrasting-color-for-nans-in-imagesc

nin = nargin;
if nin<3
    % Set NaNs to grey
    nanclr = ones(1, 3)*0.6;
end
if nin <4
    % default to min max
    rangeclr = [min(a(:)), max(a(:))];    
end

% size of colormap
n = size(cm,1);
% color step
dmap = diff(rangeclr)/n;

% standard imagesc
him = imagesc(a);
axim = gca;
axis square

% add nan color to colormap
colormap([nanclr; cm]);
% changing color limits
caxis([rangeclr(1)-dmap rangeclr(2)]);

% place a colorbar
hcb = colorbar;

% change Y limit for colorbar to avoid showing NaN color
ylim(hcb, rangeclr)
axes(axim)