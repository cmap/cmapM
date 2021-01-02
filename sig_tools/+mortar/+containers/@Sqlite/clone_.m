function result = clone_(obj, otherdb, copytoself)
% copytoself = true, source='tempxxx.', target=''
% false, source='', target='tempxxx.'

if copytoself
    source = 'tempxxx.';
    target = '';
else
    source = '';
    target = 'tempxxx.';
end

try
    % attach otherdb
    obj.run(sprintf('ATTACH "%s" as tempxxx', otherdb));
    
    obj.run('BEGIN TRANSACTION');
    % Copy all tables
    tables = obj.run(sprintf('SELECT name FROM %ssqlite_master WHERE type = "table"', source));
    for idx=1:length(tables)
        obj.run(sprintf('CREATE TABLE %s%s AS SELECT * FROM %s%s', target, tables(idx).name, source, tables(idx).name));
    end
    
    % Create indices
    indices = obj.run(sprintf('SELECT sql FROM %ssqlite_master WHERE type = "index"', source));
    for idx=1:length(indices)
        if ~isempty(indices(idx).sql)
            obj.run(indices(idx).sql);
        end
    end
catch exception
    obj.run('ROLLBACK');
    obj.run('DETACH tempxxx');
    rethrow(exception);
end
obj.run('COMMIT');
% detach
result = obj.run('DETACH tempxxx');
end