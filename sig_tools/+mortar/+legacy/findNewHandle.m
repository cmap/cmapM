function h = findNewHandle

open = get(0,'children'); 
if isempty(open)
    h = 1 ; 
else
    h = max(open) + 1; 
end