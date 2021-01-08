% renames oldname field to newname in struct s
% s = renamefield(s,oldname,newname)
% Arguments:
%	s: struct to rename fields
%	oldname: string, name of field to be renamed
%	newname: string, name to rename field 
%
% Note: MATLAB renameStructField only takes 1 x 1 struct, 
% this function accepts n x 1 or 1 x n struct array

function s = renamefield(s,oldname,newname)

if ~isfield(s,oldname)
	error('Non-existent field %s',oldname);
end

if isfield(s,newname)
	error('%s field already exists',newname);
end

%list of fieldnames - update oldname to newname
fld = fieldnames(s);
loc = ismember(fld,oldname);
fld{loc} = newname;

%append newname field
[s.(newname)] = s.(oldname);

%remove oldname field
s = rmfield(s,oldname);

%reorder
s = orderfields(s,fld);

