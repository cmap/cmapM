function h = namefig(h,lbl)
narginchk(1, 3);
if ishandle(h)
    set(h, 'name', lbl)
else
    set(gcf,'name',h)
end