function result = clone(obj, otherdb)
% Copy contents of an in-file db to the current database.
if mortar.legacy.isfileexist(otherdb)
    result = obj.clone_(otherdb, true);
else
    error('File not found');
end
end