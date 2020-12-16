function result = save(obj, out_file, overwrite)
% Save database to file
% SAVE(OUT_FILE)
% SAVE(OUT_FILE, OVERWRITE) Overwrites OUT_FILE is OVERWRITE is
% true.

if nargin>2
    overwrite = logical(overwrite);
else
    overwrite = false;
end

if mortar.legacy.isfileexist(out_file)
    if overwrite
        delete(out_file);
    else
        error('File exists not overwriting');
    end
end

result = obj.clone_(out_file, false);
end