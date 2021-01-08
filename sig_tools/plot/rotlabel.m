% ROTLABEL  Rotate X axis labels 
%   TH = ROTLABEL(H, THETA), Rotate the X tick labels in the axis H by an
%   angle THETA (degrees).
%
%   [TH, TL] = ROTLABEL(H, THETA), Returns the X tick labels
%
%   ROTLABEL(H, THETA, LOC), specifies which axis label to select and the 
%   placement of the labels. LOC can be 'top', 'bottom', 'left' or
%   'right'. Using 'top' or 'bottom' selects the X tick labels, whereas 
%   'left' and 'right' selects the Y tick labels.
%
%   Example,
%       figure
%       xl = {'zero','twenty five','fifty','seventy five','hundred'}
%       imagesc(rand(100))
%       set (gca, 'xtick',linspace(0,100,5),'xticklabel', xl)
%       rotlabel(gca, 45)
% 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [th, xl] = rotlabel(h,theta,loc)


if theta > 360
    theta =  mod(theta,360);
elseif theta <0
    error ('Theta must be >0');
end


if exist('loc','var')
    pos = lower(loc);
else
    pos = 'bottom';
end


switch (pos)
    case 'bottom'
        if theta < 180
            halign = 'right';
        else
            halign = 'left';
        end
        istop = 0;
    case 'top'
        if theta < 180
            halign = 'left';
        else
            halign = 'right';
        end
        istop = 1;
    case 'left'
        
        
    case 'right'

end

% nudge the labels a bit
fudge=0.1;

xl = texify(get(h,'xticklabel'));
xt = get(h,'xtick');
yt = get(h,'ytick');

ylims = ylim(h);
stepSize = (yt(2) - yt(1));

if (isequal(get(h,'ydir'),'reverse'))
   isreverse = true;
else
   isreverse = false;
end

if (istop && ~isreverse) || (~istop && isreverse)
    y = ylims(2);
else
    y = ylims(1);
    fudge = -fudge;
end
    
y0 = y + fudge*stepSize;

% replace with text objects
th = text(xt, repmat(y0,length(xt),1), xl, 'horizontalalignment', halign, 'rotation', theta);

% th = text(xt, repmat(y0,length(xt),1), xl, 'horizontalalignment', 'left', 'rotation', theta);

% remove default labels
set(h,'xticklabel',[]);
