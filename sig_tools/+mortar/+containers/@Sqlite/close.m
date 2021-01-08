function obj = close(obj)
% Close database
% close()
try
    if ~isempty(obj.dbid)
        mortar.legacy.dbg(obj.verbose,'Closing dbid:%d', obj.dbid);
        obj.mksqlite_bin(obj.dbid, 'close');
    end
    obj.dbid = '';
    obj.dbfile = '';
catch e
    mortar.legacy.dbg(obj.verbose, 'Database not open');
end
end
