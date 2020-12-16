function v = get_l1k_path(p)
% GET_L1K_PATH Get default paths to L1000 data
 v = parse_param(mapdir(fullfile(mortarconfig('l1k_config_path'), 'L1000_paths.txt')));
 if nargin>0
     if isfield(v, p)
         v = v.(p);
     else
         error('Unknown field: %s', p)
     end
 end
end