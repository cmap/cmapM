function retstr = struct_append(s1, s2)

% RET = STRUCT_APPEND(S1, S2)
%   Concatenates two structs with identical fields fieldwise.  That is, RET.F = vertcat(s1.F, s2.F)
%   for each F in fieldnames(s1).  Requires fieldnames(s1) = fieldnames(s2). 
%   Inputs: S1, S2 structs

if isempty(s2)
    retstr = s1;
    return;
end
if isempty(s1)
    retstr = s2;
    return;
end

if isequal(fieldnames(s1), fieldnames(s2))
	f = fieldnames(s1);
	
	for k = 1:numel(f)
		retstr.(f{k}) = vertcat(s1.(f{k}), s2.(f{k}));
	end
else 
	disp('Appendstruct: structs do not have identical field names');
	retstr = '';
end
