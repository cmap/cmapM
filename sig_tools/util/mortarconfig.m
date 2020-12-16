function v = mortarconfig(param)
% MORTARCONFIG Get configuration parameters.
% MORTARCONFIG Return all parameters
% MORTARCONFIG(PARAM) Returns the value for PARAM.

v = parse_param(fullfile(mortarpath, 'resources/mortar_config.txt'));
if nargin > 0
    if isfield(v, param)
        v = v.(param);
    else
        error('Unknown parameter: %s', param);
    end
end

end