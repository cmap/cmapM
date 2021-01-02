function lxb_rpt = validateLXB(varargin)
% validateLXB Validate LXB folder prior to espresso processing.

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    % check existence of paths
    dbg(args.verbose, '# Checking if LXB files exist');
    lxb_plate_path = fullfile(args.lxb_path, args.plate);
    assert(isdirexist(lxb_plate_path), 'LXB path %s not found', lxb_plate_path);
    [lxb_fn, lxb_fp] = find_file(fullfile(lxb_plate_path, sprintf('%s_*.lxb', args.plate)));
    [jcsv_fn, jcsv_fp] = find_file(fullfile(lxb_plate_path, sprintf('%s.jcsv', args.plate)));
    
    num_lxb = length(lxb_fn);
    num_jcsv = length(jcsv_fn);
    
    % check file and well counts
    dbg(args.verbose, '# Validate LXB content');
    assert(isequal(num_lxb, args.num_detected_wells),...
        'Mismatch in number of LXB files. Expected %d found %d',...
        args.num_detected_wells, num_lxb);    
    assert(isequal(num_jcsv, 1),...
        'Mismatch in number of JCSV files. Expected 1 found %d',...
        num_jcsv);   
    lxb_rpt = struct('plate', args.plate,...
        'lxb_plate_path', lxb_plate_path,...
        'jcsv_path', jcsv_fp,...
        'num_lxb', num_lxb,...
        'num_jcsv', num_jcsv);
    dbg(args.verbose, '# Done validating LXBs');
end

end

function [args, help_flag] = getArgs(varargin)
pnames = {'--lxb_path', '--plate', '--num_detected_wells', '--verbose'};
dflts = {'', '', 384, true};
help_str = {'Path containing LXB folders',...
    'Detecttion plate name',...
    'Number of wells detected',...
    'Print debug messages'};
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Validate LXB inputs for espresso');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

end