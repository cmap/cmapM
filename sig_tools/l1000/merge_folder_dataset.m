function combods = merge_folder_dataset(varargin)
% MERGE_FOLDER_DATASET Merge datasets from a set of folders.
%   COMBODS=MERGE_FOLDER_DATASET('plate', P, 'plate_path', PP)
%
%
% Example:
% merge_folder_dataset('plate','brews.grp','plate_path','pp',
% 'out','out_path','dstype','COMPZ.MODZ_SCORE_LM','location','by_rna_well')

toolName = mfilename;
% parse args
pnames = {'plate', 'overwrite', 'debug',...
    'rpt', 'precision', 'dstype',...
    'out', 'name', 'use_gctx',...
    'location', 'rid','cid',...
    'exclude_cid', 'exclude_rid', 'qnorm',...
    'row_filter', 'column_filter',...
    'fix_meta', 'plate_path', 'skip_annot'};

dflts =  {'', false, false,...
    toolName, 4, 'QNORM', ...
    '', 'merged', true, ...
    '', '', '',...
    false, false, false,...
    '', '',...
    false, '', false};

args = parse_args(pnames, dflts,varargin{:});
%print_args(toolName, 1, args);

if any(isfileexist(args.plate))
    plates = parse_grp(args.plate);
elseif iscell(args.plate)
    plates = args.plate;
elseif ischar(args.plate)
    plates = {args.plate};
else
    error('Plate should be .grp or cell or char');
end

% check and exclude duplicates
dup_plate = duplicates(plates);
if ~isempty(dup_plate)
    warning('Ignoring %d duplicate plates specified', length(dup_plate))
    disp(dup_plate)
    plates = unique(plates, 'stable');
end

% output to folder with plates grp file
%if isempty(args.out) && isfileexist(args.plate)
%    args.out = fileparts(args.plate);
%end

nplate = length(plates);
dsname = cell(nplate, 1);

for pn=1:nplate
    % get plate info
    %     plateinfo = parse_platename(plates{pn}, varargin{:}, 'verify',false);
    plate_root = fullfile(args.plate_path, plates{pn});
    % check if data file exists
    dspath = fullfile(plate_root, args.location, ...
        sprintf('%s_%s*.gct*', plates{pn}, args.dstype));
    [fn, fp] = find_file(dspath);
    if isequal(length(fn),1)
        dsname{pn} = fp{1};
    elseif ~isempty(fn)
        disp(fp)
        error('Multiple entries found for %s', dspath);
    else
        error('%s not found', dspath)
    end
end

fprintf('Merging %d plates\n', nplate);
combods = merge_profile(dsname, 'cid', args.cid, ...
    'exclude_cid', args.exclude_cid,...
    'rid', args.rid, 'exclude_rid', args.exclude_rid,...
    'row_filter', args.row_filter,...
    'column_filter', args.column_filter,...
    'ignore_missing', true, 'fix_meta', args.fix_meta,...
    'skip_annot', args.skip_annot);

% quantile normalization
if args.qnorm
    combods.mat = qnorm(combods.mat);
end
if ~isempty(args.out)
    if args.use_gctx
        mkgctx(fullfile(args.out, ...
            sprintf('%s_%s.gctx', args.name, args.dstype)), combods);
    else
        mkgct(fullfile(args.out, ...
            sprintf('%s_%s.gct', args.name, args.dstype)), combods, ...
            'precision', args.precision);
    end
end

end
