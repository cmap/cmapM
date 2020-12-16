function obj = open(obj, dbfile)
% Connect to a database
% connect(dbfile)
if nargin == 2 && ischar(dbfile)
    if ~isempty(obj.dbid)
        obj.close;
    end
    try
        obj.dbid = obj.mksqlite_bin(0, 'open', dbfile);
        obj.mksqlite_bin(sprintf('PRAGMA synchronous = %s', obj.sync_mode));
    catch e
        error('Error opening db file');
    end
    obj.dbfile = dbfile;
    mortar.legacy.dbg(obj.verbose, 'Connected to %s (%d)', obj.dbfile, obj.dbid);
else
    obj.dbid = '';
    obj.dbfile = '';
end
end