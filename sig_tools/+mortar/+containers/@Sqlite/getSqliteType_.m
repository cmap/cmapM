function dtype = getSqliteType_(matlab_type)
% Convert Matlab data type to Sqlite type
dtype = '';
switch (lower(matlab_type))
    case {'char'}
        dtype = 'TEXT';
    case {'single','double'}
        dtype = 'REAL';
    case {'int8', 'int16', 'int32', 'int64', 'uint8', ...
            'unit16', 'unit32', 'uint64', 'logical'}
        dtype = 'INTEGER';
    otherwise
        error('Unknown type: %s', matlab_type)
end
end
