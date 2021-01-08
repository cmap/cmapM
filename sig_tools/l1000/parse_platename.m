function res = parse_platename(p, varargin)
% PARSE_PLATENAME Parse an L1000 plate name
%   RES = PARSE_PLATENAME(P)
%   P should be upper case
%   RES fields
%       plate:
%       raw_path:
%       plate_path:
%       csv_path:
%       sample_map:
%       invset:
%       yref:
%       chip:
%       detmode:
%       bset:
%       bset_revision:
%       pool:
default_path = get_l1k_path;
pnames = {'raw_path', ...    
    'verify', ...
    'plate_path',...
    'map_path',...
    'pool_info',...
    'bead_batch_info',...
    'mapversion',...
    'use_jcsv',...
    'default_det_mode',...
    'detect_param'};
dflts = {default_path.raw_path,...        
        true,...
        '',...
        default_path.map_path,...
        fullfile(mortarconfig('l1k_config_path'), 'L1000_poolinfo.txt'),...
        fullfile(mortarconfig('l1k_config_path'), 'L1000_bead_batch.txt'),...
        '2.2',...
        false,...
        'DUO52HI53LO',...
        ''};
if ~exist('p','var')||isempty(p)    
    error('No plate name specified')
end
args = parse_args(pnames, dflts, varargin{:});

if (ischar(p) && ~isempty(regexp(p,'.grp$', 'once')))
    p = parse_grp(p);
elseif ischar(p)
    p = {p};
elseif ~iscell(p)
    error('Plates should be a cell array or a string. Found :%s', class(p))
end

nplate = length(p);

res(1:nplate, 1) = struct('plate', p,...
    'raw_path', '',...    
    'csv_path', '',...
    'sample_map', '',...
    'local_map', '',...
    'invset', '',...
    'yref', '',...
    'chip', '',...
    'missing_analytes', '',...
    'notduo', '',...
    'detmode', '',...
    'bset', '',...
    'bset_revision', '',...
    'bead_batch', '',...
    'pool', '',...
    'plate_path', '',...
    'detect_param', '');

for ip=1:nplate
    res(ip) = parse_one_plate(p{ip}, args);
end
end

function res = parse_one_plate(p, args)

res = struct('plate', p,...
    'raw_path', '',...    
    'csv_path', '',...
    'sample_map', '',...
    'local_map', '',...
    'invset', '',...
    'yref', '',...
    'chip', '',...
    'missing_analytes', '',...
    'notduo', '',...
    'detmode', '',...
    'bset', '',...
    'bset_revision', '',...
    'bead_batch', '',...
    'pool', '',...
    'plate_path', '',...
    'detect_param', '');

res.plate = p;
tok = tokenize(p, '_');
modes = {'uni', 'duo', 'onebs'};
nmodes = length(modes);

%output folder
if isempty(args.plate_path) && args.verify
    error('Plate path folder not specified');
end
res.plate_path = fullfile(args.plate_path, p);
if ~isdirexist(res.plate_path) && args.verify
    mkdir(res.plate_path);
end

%raw data path
res.raw_path = fullfile(args.raw_path, p);
if args.verify && ~isfileexist(res.raw_path, 'dir')
    error('Raw data path not found: %s', res.raw_path);
end

%csv path
if args.verify
    if args.use_jcsv
        d = dir(fullfile(res.raw_path,'*.jcsv'));
    else
        d = dir(fullfile(res.raw_path,'*.csv'));
    end
    if isempty(d)
        error('No CSV file found at: %s', res.raw_path);
    else
        if length(d)>1
            disp({d.name}')
            error('Multiple CSV files found at: %s', res.raw_path);
        else
            res.csv_path = fullfile(res.raw_path, d(1).name);
        end
    end
else
    res.csv_path = fullfile(res.raw_path, sprintf('%s.csv', p));
end

% plate path
% res.plate_path = fullfile(arg.plate_path, p);
% if arg.verify && ~isfileexist(res.plate_path, 'dir')
%     error('Plate data path not found: %s', res.plate_path);
% end

%sample map
res.sample_map = fullfile(args.map_path, sprintf('%s.map', p));
res.local_map = fullfile(res.plate_path, sprintf('%s.map', p));
if args.verify && ~isfileexist(res.sample_map)
    error('Sample map not found: %s', res.sample_map);
% copy map file to outpath
elseif args.verify && isfileexist(res.sample_map) && ~isfileexist(res.local_map)    
    cp(res.sample_map, res.local_map);
    status = chmod(res.local_map, '664');
    % Auto insert det plate and det well info, if not specified explicitly
    try
        format_mapfile(res.local_map);
    catch me
        dbg(1, '%s:%s', me.identifier, me.message);
        error('Unable to update map file, check permissions: %s', res.local_map);
    end
end

% detection mode
if isequal(length(tok), 5)
    % default det mode if not specified
    tok{6} = args.default_det_mode;
    match = 6;
    res.detmode = 'duo';
else    
    for ii=1:nmodes
        match = find(cellfun(@length,regexpi(tok,sprintf('^%s',modes{ii}))), 1);
        if ~isempty(match)
            res.detmode = modes{ii};
            break;
        end
    end
end

%bead set info
switch res.detmode
    case 'uni'
        try
            res.bset = strcat('dp', {tok{match}(4:5), tok{match}(6:7)});            
        catch e
            disp(e.identifier)
            error('Invalid bead set info in: %s',res.detmode);
        end
    case 'duo'
        try
            hibset = tok{match}(regexpi(tok{match},'hi') + [-2, -1]);
            lobset = tok{match}(regexpi(tok{match},'lo') + [-2, -1]);
            %res.bset = strcat('dp', {tok{match}(4:5), tok{match}(8:9)});
            res.bset = strcat('dp', {hibset, lobset});
        catch e            
            disp(e.identifier)
            error('Invalid bead set info in: %s', res.detmode);
        end
    case 'onebs'
            res.bset = lower(tok(end));
    otherwise
        error('Unknown detection mode:%s', p);
end

if args.verify && ~isequal(length(unique(res.bset)),2) && ~isequal(res.detmode, 'ONEBS')
    error ('Two distinct bead sets not specified:%s', p)
end

% parse the sample map for pool information
% if  isfileexist(res.sample_map) || 1
   
%     [pool_bset_dict, pool_annot_dict] = parse_poolinfo(arg.pool_info);
    [bset2pool, pool2annot, pool2bset] = parse_poolinfo(args.pool_info);
    switch args.mapversion
        case '2.0'
            % probe pool
            res.pool = lower(smap(1).pool);
            smap_bset = lower(tokenize(smap(1).bsets, ','));
        case '2.1'
            smap = parse_record(res.sample_map, 'lowerhdr',true);
            % probe pool
            res.pool = lower(smap(1).pool_name);
            smap_bset = lower(tokenize(smap(1).bead_set, ','));
        case '2.2'
            %             res.pool = lower(smap(1).exp_pool_id);
            %             smap_bset = lower(tokenize(smap(1).exp_bead_set, ','));
            %             res.bset_revision = upper(smap(1).exp_bead_revision);
            
            res.bead_batch = tok{match-1};
            % Use bead_batch to infer pool
            bead_batch_info = parse_record(args.bead_batch_info);
            this_bead_batch = filter_table(bead_batch_info,...
                {'exp_bead_batch_id'}, {res.bead_batch},...
                'matchtype', 'exact');
            assert(isequal(length(this_bead_batch), 1), 'Bead batch %s does not map to a unique record in %s', res.bead_batch, args.bead_batch_info);
            res.pool = this_bead_batch.exp_pool_id;
            % Use beads sets to infer pool            
            %pool=unique(bset2pool.values(res.bset));
            %if length(pool)>1
            %    disp(res.bset);
            %    error('Beadsets are not from the same pool')
            %end
            %res.pool = pool{1};
            
            
            batch_info = filter_table(args.bead_batch_info,...
                {'exp_pool_id','exp_bead_batch_id'},...
                {res.pool,res.bead_batch},'matchtype','exact');
            if args.verify && length(batch_info) ~= 1
                error('Invalid Batch info');
            end
            if ~isempty(batch_info)
                res.bset_revision = batch_info.exp_bset_revision;
            end
    end
%     if args.verify && ~pool_bset_dict.isKey(res.pool)
%         error('Invalid pool specified: %s', res.pool);
%     end
    % check if bsets valid for pool
    % Pool + revision
    pool_rev = lower(sprintf('%s:%s', res.pool, res.bset_revision));
    if args.verify && ...
            ~isequal(length(res.bset), length(intersect(res.bset, pool2bset(pool_rev))))
        setdiff(pool2bset(pool_rev), res.bset)
        error('Bset(s) not found in pool %s', res.pool);
    end
    
    % check if bsets in name matches map
    assert(pool2annot.isKey(pool_rev),... 
           'Pool revision %s%s not recognized', pool_rev, res.bead_batch);
   
    annot = pool2annot(pool_rev);
    res.chip = annot.chip_file;
    res.invset = annot.invset_file;
    res.yref = annot.yref_file;
    res.detect_param = ifelse(~isempty(args.detect_param), args.detect_param, annot.detect_param);    
    
    if args.verify
        assert(mortar.util.File.isfile(res.chip), 'Chip file %s not found', res.chip);
        assert(mortar.util.File.isfile(res.invset), 'Invset file %s not found', res.invset);
        assert(mortar.util.File.isfile(res.yref), 'YRef file %s not found', res.yref);
        assert(mortar.util.File.isfile(res.detect_param), 'Detect Param file %s not found', res.detect_param);
    end
    
    % missing analytes
    tok = tokenize(annot.missing_analytes, ',');
    match = print_dlm_line(res.bset, 'dlm', '|');
    res.missing_analytes = tok(~cellfun(@isempty, regexpi(tok, match)))';
    
    % not duo analytes
    res.notduo = annot.not_duo;
    
% else
%     warning('Sample map not found, pool and invariant set info not available.');
% end

end

