function ge_sorted = rearrangerows(ge_inf,L,L_dep,remaining)
    
% ge_inf is stacked landmark on inferred/dependent/remaiing
if nargin == 4
    ix_list = [ L(:) ; L_dep(:) ; remaining(:) ] ; 
else
    ix_list = [ L(:) ; L_dep(:) ];
end
ge_sorted = zeros(size(ge_inf)); 
for i = 1 : length(ix_list)
    ge_sorted(ix_list(i),:) = ge_inf(i,:); 
end

end