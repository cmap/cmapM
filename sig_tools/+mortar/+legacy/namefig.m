function h = namefig(h,lbl)
error(nargchk(1,3,nargin),'Not enought input arguments');
if ishandle(h)
    set(h, 'name', lbl)
else
    set(gcf,'name',h)
end