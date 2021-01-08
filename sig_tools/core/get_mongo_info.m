function info = get_mongo_info(mongo_info, mongo_location)
% Get mongo connection info

server = parse_tbl(mongo_info, 'verbose', false, 'outfmt', 'record');
server_idx = strcmpi(mongo_location, {server.mongo_location});
assert(any(server_idx), 'Server location not found: %s', mongo_location);

info = server(server_idx);

end