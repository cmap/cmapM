function dactyloscopy_pipe(varargin)

toolname = mfilename;
fprintf('##[ %s ]## BEGIN...\n', upper(toolname));
start_time = tic;
% parse function arguments
pnames = {'plate', 'raw_path', 'plate_path', 'overwrite', 'randomize'};
dflts = {'', '', '', false, false};
args = parse_args(pnames, dflts, varargin{:});
if ~isempty(regexp(args.plate,'.grp$', 'once'))
    plates = parse_grp(args.plate);
    if args.randomize
        plates = plates(randperm(length(plates)));
    end
elseif ischar(args.plate)
    plates = {args.plate};
end
P = length(plates);
% loop over all plates
for p = 1:P
    plate = plates{p};
    % get plate info
    plateinfo = parse_platename(plate, varargin{:});
    % find gct file with qnorm level data
    gct_file = dir(fullfile(plateinfo.plate_path,strcat(plateinfo.plate,'_QNORM*.gct')));
    plateinfo.qnorm_gct_path = gct_file.name;
    path_to_qnorm_gct = fullfile(plateinfo.plate_path, plateinfo.qnorm_gct_path);
    % check if dactyloscopy folder exists
    d = dir(fullfile(plateinfo.plate_path, 'dactyloscopy', 'dactyloscopy_test_*.txt'));
    % set output directory
    dname_out = fullfile(plateinfo.plate_path, 'dactyloscopy');
    %d = dir(fullfile(plateinfo.plate_path, 'dactyloscopy'));
    direxists = ~isempty(d);
    if ~args.overwrite && direxists
        fprintf('%s: dactyloscopy folder exists, skipping...\n', plateinfo.plate);
    else
        lockfile = fullfile(plateinfo.plate_path,sprintf('%s.lock',plateinfo.plate));
        if lock(lockfile)    
            % make work output directory
            mkworkfolder(plateinfo.plate_path, 'dactyloscopy', 'forcesuffix', false, ...
                'overwrite', true);
            
	    % run dactyloscopy_single
            dactyloscopy_single(path_to_qnorm_gct,'--save_out',true,'--dname_out',dname_out);
            
	    % run dactyloscopy_make_plots
	    my_dmp = DactyloscopyMakePlots(dname_out);
            my_dmp.make_plots('--save_out',true)
            
	    unlock(lockfile);
        else
            fprintf('%s: locked, skipping...\n', plateinfo.plate);
        end
    end
end
fprintf('##[ %s ]## END. (%2.2fs)\n', upper(toolname), toc(start_time));

end
