function map_rpt = validateMapSource(varargin)
[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    
    % check for existence
    dbg(args.verbose, '# Checking if map source exists');
    pp = plateparts(args.plate);
    map_src_file = fullfile(args.map_src_path, sprintf('%s.src', pp(1).pert_plate));
    [map_fn, map_fp] = find_file(map_src_file);
    num_map = length(map_fn);
    assert(isequal(num_map, 1), 'Map source file %s not found', map_src_file);
    
    % parse and validate map file
    dbg(args.verbose, '# Validating map source file');
    map_tbl = parse_record(map_fp{1});
    check_struct_field(map_tbl, args.required_map_src_fields, 'error');
    num_well = length(map_tbl);
    
    map_rpt = struct('plate', args.plate,...
                     'num_well', num_well);
    dbg(args.verbose, '# Done validating map source');                
end

end


function [args, help_flag] = getArgs(varargin)
pnames = {'--map_src_path', '--plate', '--required_map_src_fields', '--verbose'};
dflts = {'', '', {}, true};
help_str = {'Path containing map source files',...
    'Detection plate name',...
    'Required fields in map src',...
    'Print debug messages'};
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Validate Map source inputs for espresso');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
end