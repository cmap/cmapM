function [L,Ldep,found] = getlists(gn,landmarks,dependent)
% Returns indices of landmarks and dependent labels found in gn

[~,L] = intersect_ord(gn,landmarks);
[~,Ldep] = intersect_ord(gn,dependent);
    
found = true; 
if length(Ldep) ~= length(dependent) 
    found = false ; 

end
if length(landmarks) ~= length(L)
    found = false ; 
 
end

end