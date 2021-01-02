function result = run(obj, sql_query)
% Run an SQL query
if ~isempty(obj.dbid)
    if ischar(sql_query)
        sql_query = {sql_query};
    end
    args = mortar.legacy.parse_args(obj.opt_param, obj.opt_default, sql_query{2:end});
    try
        result = obj.mksqlite_bin(obj.dbid, sql_query{1});
        if args.as_cell
            % use alternate format if requested
            if args.header
                result = [fieldnames(result), struct2cell(result)]';
            else
                result = struct2cell(result)';
            end
        end
    catch e
        disp(e.identifier)
        disp(e.message)
        error('Error executing command: \n%s', sql_query{1})
    end
else
    result = '';
end
end