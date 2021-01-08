function v = mortarconfig(param)
% MORTARCONFIG Get configuration parameters.
% MORTARCONFIG Return all parameters
% MORTARCONFIG(PARAM) Returns the value for PARAM.

v = get_config_info;
if nargin > 0
    if isfield(v, param)
        v = v.(param);
    else
        error('Unknown parameter: %s', param);
    end
end

end


function res = get_config_info(refresh_cache)
% CHIP_INFO get infomation on all chips
if isequal(nargin, 1)
    do_refresh = refresh_cache;
else
    do_refresh = false;
end
persistent config_info_;
if isempty(config_info_) || do_refresh
   config_info_ = parse_param(fullfile(mortarpath, 'resources/mortar_config.txt'));    
end
% override these variables since they have dedicated functions
config_info_.vdb_path = vdbpath;
config_info_.mortar_path = mortarpath;
config_info_.l1k_config_path = fullfile(config_info_.vdb_path, 'roast');
config_info_.mongo_config_path = fullfile(config_info_.vdb_path, 'mongo');

res = config_info_;
end