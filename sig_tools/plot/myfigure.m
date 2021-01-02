function h=myfigure(showfig, varargin)
% MYFIGURE Create a blank figure
% H=MYFIGURE
% H=MYFIGURE(SHOWFIG) where SHOWFIG is boolean. Creates an
% invisible figure when SHOWFIG is false.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if ~exist('showfig','var')
    showfig=true;
end

if showfig
    h=figure(varargin{:});
else
    h=figureoff(varargin{:});
end
