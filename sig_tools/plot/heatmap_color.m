%HEATMAP_COLOR Compute color values for plotting a gene expression heatmap.
%
%   COLORVAL = HEATMAP_COLOR(M) converts the expression values in M to
%   color values suitable for visualization using imagesc.
%
%   See also BLUEPINK

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function cind = heatmap_color(m)
%computeRelativeMeanColor from GSEA


%% bsxfun offers memory savings and speedup

%row-wise min,max,mean values
mmin = min(m,[],2);
mmax = max(m,[],2);
mmiddle = mean(m,2);


% sigma=std(m,0,2);
% mmin = -3*sigma; 
% mmax = 3*sigma;
% 
% %clamp outlier values
% minind = bsxfun(@lt,m,mmin);
% maxind = bsxfun(@gt,m,mmax);
% 
% m = m.*~minind + bsxfun(@times,minind,mmin);
% m = m.*~maxind + bsxfun(@times,maxind,mmax);

%colormap 
cm = bluepink;
numColors = length(cm);

leind = bsxfun(@le,m,mmiddle);
gind = ~leind;

cind = leind .* bsxfun (@rdivide,bsxfun(@minus,m,mmin) , bsxfun(@minus,mmiddle,mmin));

cind = cind + gind .* (1 + bsxfun(@rdivide, bsxfun(@minus,m,mmiddle) , bsxfun(@minus,mmax, mmiddle)));

cind = round(cind * (numColors-1) * 0.5)+1;

%%the slow loop version
% [nr,nc] = size(m);
% cind = zeros(nr,nc);
% 
% for r=1:nr;
%     rmin = min(m(r,:));
%     rmax = max(m(r,:));
%     rmiddle = mean(m(r,:));
% 
%     cm = bluepink;
%     numColors = length(cm);
% 
%     %computeRelativeMeanColor from GSEA
%     leind = m(r,:)<=rmiddle;
%     gind = ~leind;
% 
%     cind(r,leind) = (numColors-1) * 0.5 * (m(r,leind) - rmin) / (rmiddle - rmin);
%     cind(r,gind) = (numColors-1) * 0.5 * (1 + (m(r,gind) - rmiddle) / (rmax - rmiddle));
% 
%     cind(r,:) = round(cind(r,:))+1;
% end

%% vectorized using repmat
% [nr,nc] = size(m);
% 
% mmin = repmat(min(m,[],2),1,nc);
% mmax = repmat(max(m,[],2),1,nc);
% mmiddle = repmat(mean(m,2),1,nc);
% 
% cm = bluepink;
% numColors = length(cm);
% 
% cind = zeros(size(m));
% 
% %computeRelativeMeanColor from GSEA
% leind = m<=mmiddle;
% gind = ~leind;
% 
% cind(leind) = (numColors-1) * 0.5 * (m(leind) - mmin(leind)) ./ (mmiddle(leind) - mmin(leind));
% cind(gind) = (numColors-1) * 0.5 * (1 + (m(gind) - mmiddle(gind)) ./ (mmax(gind) - mmiddle(gind)));
% 
% cind = round(cind)+1;
