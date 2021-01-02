function lim = geteqlim(xlimit,ylimit)
% GETEQLIM Equalize axis limits
%   GETEQLIM(xlimit,ylimit) will set the axis limits equal, with the wider
%   been common limit

lim = zeros(1,2); 
if xlimit(2) > ylimit(2)
    lim(2) = xlimit(2) ; 
else
    lim(2) = ylimit(2) ; 
end

if xlimit(1) < ylimit(1)
    lim(1) = xlimit(1) ; 
else
    lim(1) = ylimit(1); 
end