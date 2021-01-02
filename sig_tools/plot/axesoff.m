function ha=axesoff(varargin)

nin=nargin;
if (nin>0 && all(ishandle(varargin{1})))
    % handle of current figure
    cf = get(0,'CurrentFigure');
    % handle of current axes of current figure    
    ca = get(cf, 'CurrentAxes');
    ha = varargin{1};
    if ~isequal(ca, ha)
        ph = get(ha, 'parent');
        vis = get(ph, 'visible');
        axes(ha);
        set (ph, 'visible', vis);
    end
else
end


end