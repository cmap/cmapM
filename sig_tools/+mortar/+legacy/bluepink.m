% BLUEPINK Colormap for MIT gene-expression heatmaps
%
%   CM = BLUEPINK returns colormap matrix

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function cm=bluepink

cm = [
      69 0 173;
      39 0 209;
      107 88 239;
      136 136 255;
      199 193 255;
      213 213 255;
      255 192 229;
      255 137 137;
      255 112 128;
      255 90 90;
      239 64 64;
      214 12 0;
       ]/255;

% %MIT Heat map color scheme
% %12 colors blue to red
%  cm = [
%       39 0 173;
%       69 0 209;
%       107 88 239;
%       136 136 255;
%       199 193 255;
%       213 213 255;
%       255 192 229;
%       255 137 137;
%       255 112 128;
%       255 90 90;
%       239 64 64;
%       214 12 0;
%       ]/255;
       
% if(0)
%   cols=[
%       69 0 173;
%       39 0 209;
%       107 88 239;
%       136 136 255;
%       199 193 255;
%       213 213 255;
%       255 192 229;
%       255 137 137;
%       255 112 128;
%       255 90 90;
%       239 64 64;
%       214 12 0;
%        ];
%   
%   
%   
%   cols2=zeros(64,3);
%   for i=1:size(cols2,1)
%     r=((1:64)-1)*((size(cols,1)-1)/63)+1;
%     b=floor(r(i));
%     f=r(i)-b;
%     if (f>0)
%       cols2(i,:)=cols(b,:)+f*(cols(b+1,:)-cols(b,:));
%     else
%       cols2(i,:)=cols(b,:);
%     end
%   end
% end
% 
% cols2=255*ones(64,3);
% cols2(1:32,1:2)=repmat((255/32)*(0:31)',1,2);
% %cols2(1:32,3)=255;
% cols2(33:64,2:3)=repmat((255/32)*(31:-1:0)',1,2);
% %cols2(33:64,1)=255;
% cols2=round(cols2);
% 
% %cols2(:,1)=resample(cols(:,1),64,12);
% %cols2(:,2)=resample(cols(:,2),64,12);
% %cols2(:,3)=resample(cols(:,3),64,12);
% % cols2(cols2>255)=255;
% % cols2(cols2<0)=0;
% cols2=cols2/255;
% 
% if nargout>0
%   cm=cols2;
% else
%   colormap(cols2);
%   cm=[];
% end
% 
% % test colors
% % figure(2); clf;
% % imagesc(rand(100,100));
% % colorbar;
% % colormap(cols2);
% 
% 
% 
