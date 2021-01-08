function fname = pullname(file) 

ix = find(file=='/'); 
if ~isempty(ix)
    file = file(ix(end)+1:end); 
end
end_pt = find(file=='.'); 
if ~isempty(end_pt)
    fname = file(1:end_pt-1); 
else
    fname = file; 
end