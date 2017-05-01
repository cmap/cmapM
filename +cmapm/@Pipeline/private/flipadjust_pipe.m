function combods = flipadjust_pipe(varargin)
% FLIPADJUST_PIPE: Apply plate-level flip correction.

% Inputs:
% RAW gex
% COUNT, PCTCOUNT
% QC stats
%
% Output:
% beadset level GEX
% combined GEX file
% if DUO check for RAW

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
start_time = tic;
% parse args
pnames = {'plate', 'overwrite', 'debug',...
    'rpt', 'flip_correct', 'use_smdesc',...
    'precision', 'usecount', 'maxiter',...
    'flip_cutoff', 'flip_method', 'usepct'};
dflts =  {'', false, false, ...
    toolname, true, false,...
    4, true, 100,...
    0.4, 'linear', false};
arg = parse_args(pnames, dflts,varargin{:});            
print_args(toolname, 1, arg);
if ~isempty(regexp(arg.plate, '.grp$', 'once'))
    plates = parse_grp(arg.plate);
else
    plates = {arg.plate};
end
nplate = length(plates);

for pn=1:nplate
    % get plate info
    plateinfo = parse_platename(plates{pn}, varargin{:});
    % Applies only to DUO
    if isequal(plateinfo.detmode, 'duo')
        % check if combo GEX file exists
        gex_path = dir(fullfile(plateinfo.plate_path, sprintf('%s_GEX_*.gct',...
            plateinfo.plate)));
        gexexists = ~isempty(gex_path);        
        % Dataset(s)
        dspath = fullfile(plateinfo.plate_path,'dpeak');
        d = dir(fullfile(dspath, sprintf('*_RAW_*.gct')));
        ds = strcat(dspath, filesep, {d.name}');
        nds = length(ds);
        if isequal(nds, length(plateinfo.bset))
            rawexists = true;
        else
            rawexists = false;
        end        
        if ~arg.overwrite && gexexists
            fprintf('%s: GEX exists, skipping...\n', plateinfo.plate);
            % parse and return the existing GEX matrix
            combods = parse_gct(fullfile(plateinfo.plate_path, gex_path(1).name));
        else
            if rawexists
                % lockfile = fullfile(plateinfo.plate_path,sprintf('%s.lock',...
                %     plateinfo.plate));
                % if lock(lockfile)
                wkdir = mkworkfolder(plateinfo.plate_path, 'dpeak', ...
                    'forcesuffix', false, 'overwrite', true);
                fprintf ('Saving analysis to %s\n',wkdir);
                fid = fopen(fullfile(wkdir, sprintf('%s_params.txt',...
                    toolname)), 'wt');
                print_args(arg.rpt, fid, arg);
                fclose (fid);

                % path for figures
                figdir = mkworkfolder(wkdir, 'figures', ...
                    'forcesuffix', false, 'overwrite', true);
                
                % sample map
                welldict = map_samples(plateinfo.local_map, plateinfo, ...
                    'use_smdesc', arg.use_smdesc, varargin{:});

                %order RAW files based on gradient
                ord = find(~cellfun(@isempty, regexp(ds, ...
                    plateinfo.bset{1})));
                if ord>1
                    ds = ds([2,1]);
                end
                %Load RAW files
                raw = parse_gct_multi(ds, 'version', '2');
                wells = get_wellinfo(raw(1).cid);
                vals = welldict.values(wells);
                profname = cellfun(@(x) x.prof_name, vals, ...
                    'uniformoutput', false);
                % apply flip correction
                if arg.flip_correct
                    if arg.usecount
                        fprintf ('Applying 2d flip correction: EXP + COUNT\n');                            
                        if arg.usepct
                            dscnt = strrep(ds, '_RAW_', '_PCTCOUNT_');
                        else
                            dscnt = strrep(ds, '_RAW_', '_COUNT_');
                        end
                        cnt = parse_gct_multi(dscnt, 'version', '2');
                        [adj, flipds.mat, post] = iterative_flip_adjust_2d(raw,...
                            cnt, varargin{:}, 'not_duo', eval(plateinfo.notduo));
                        % add process code
                        % adj(1) = update_provenance(adj(1), 'flipadjust', 'adjust_2d');
                        % adj(2) = update_provenance(adj(2), 'flipadjust', 'adjust_2d');
                    else
                        fprintf ('Applying 1d flip correction: EXP\n');
                        [adj, flipds.mat] = iterative_flip_adjust(raw, ...
                            varargin{:});
                        % add process code
                        adj(1) = update_provenance(adj(1), 'flipadjust', 'adjust_1d');
                        adj(2) = update_provenance(adj(2), 'flipadjust', 'adjust_1d');
                    end
                    % save flips stats
                    rdict = list2dict(raw(1).rhd);
                    flipds.rid = gen_labels(cell2mat(raw(1).rdesc(:, ...
                        rdict('pr_analyte_num'))), 'prefix', 'Analyte ',...
                        'zeropad', false);
                    flipds.rhd = {};
                    flipds.rdesc = {};
                    flipds.cid = profname;
                    flipds.chd = raw(1).chd;
                    flipds.cdesc = raw(1).cdesc;
                    mkgct(fullfile(wkdir, ...
                        'flipstats.gct'),...
                        flipds, 'precision', 0);
                else
                    adj = raw;
                end
                % save GEX files
                % bead set data
                for ii=1:length(plateinfo.bset)
                    mkgct(fullfile(wkdir, ...
                        sprintf('%s_GEX.gct', plateinfo.bset{ii})),...
                        adj(ii), 'precision', arg.precision);
                    if arg.flip_correct
                    % posterior probabilities
                    mkgct(fullfile(wkdir, ...
                        sprintf('%s_PROB.gct', plateinfo.bset{ii})),...
                        post(ii), 'precision', arg.precision);
                    end
                end
                % combo GEX
                combods = combinegct(adj, 'keepshared', false);
                % use profile names
                combods.cid = profname;                    
                mkgct(fullfile(plateinfo.plate_path, ...
                    sprintf('%s_GEX.gct', plateinfo.plate)), ...
                    combods, 'precision', arg.precision);
                %post-deak figures
                % post_dpeak_figures(plateinfo.plate_path, 'figdir', figdir);                    
                % unlock(lockfile);
                % else
                %     fprintf('%s: locked, skipping...\n', plateinfo.plate);
                % end
            end
        end
    end
end

fprintf('-[ %s ]- Done. (%2.2fs)\n', upper(toolname), toc(start_time));
end