function [smdict, wpairs]  = map_samples(smapfile, plateinfo, varargin)
% MAP_SAMPLES  well to sample mapping.
% returns well to sample map dictionary
% Required map fields:
% rna_plate
% rna_well
% det_plate
% det_well

pnames = {'mapversion', 'assume_lma_controls', 'lma_cfg'};
dflts = {'2.2', false, fullfile(cmapmpath, 'resources', 'L1000_control_wells.txt')};
args = parse_args(pnames, dflts, varargin{:});
% control wells (assumes same in all plates)
ctl_wells = parse_tbl(args.lma_cfg);
ctl_meta = setdiff(fieldnames(ctl_wells), 'rna_well');
if isstruct(smapfile)
    smap = smapfile;
else
    smap = parse_tbl(smapfile, 'outfmt', 'record');
end

switch args.mapversion
    case '2.2'
        % required fields
        required = {'rna_plate','rna_well',...
            'det_plate', 'det_well', 'pert_type'};
        
        fn = fieldnames(smap);
        if ~isequal(length(intersect(fn, required)), length(required))
            disp(setdiff(required, fn));
            error('Required fields missing from map file');
        end
        % any number of descriptor fields
        descfields = setdiff(fn, {'id', 'sample_id', 'pool_id', 'name'});
        wpairs = tokenize({smap.det_well},',',true);
        % plateinfo fields to include
        pidict = containers.Map({'bead_set', 'pool_id',...
            'det_mode', 'bead_batch',...
            'bead_revision'}, ...
            {{print_dlm_line(plateinfo.bset,'dlm',',')}, {plateinfo.pool}, ...
            {plateinfo.detmode}, lower({plateinfo.bead_batch}), ...
            lower({plateinfo.bset_revision})});
        
        % create well to sample map
        smdict = containers.Map();
        for ii=1:length(smap)
            detwells = tokenize(smap(ii).det_well, ',', true);
            for jj=1:length(detwells)
                desc = containers.Map();            
                for kk=1:length(descfields)
                    desc(descfields{kk}) = {smap(ii).(descfields{kk})};
                end
                % append pidict. Note will overwrite keys that exist in
                % dict
                desc = [desc; pidict];
                
                % override map settings for lma control wells
                if args.assume_lma_controls
                    islma_ctl = ismember(ctl_wells.rna_well, smap(ii).rna_well);
                    if any(islma_ctl)
                        for kk=1:length(ctl_meta)
                            desc(ctl_meta{kk}) = ctl_wells.(ctl_meta{kk})(islma_ctl);
                        end
                    end
                end
                prof_name = sprintf('%s:%s', smap(ii).det_plate, smap(ii).rna_well);
                vals = struct('det_name', sprintf('%s:%s', smap(ii).det_plate, detwells{jj}), ...
                    'sm_desc', desc, ...
                    'prof_name', prof_name,...
                    'bset', plateinfo.bset,...
                    'pool', plateinfo.pool,...
                    'det_mode', plateinfo.detmode,...
                    'det_well', smap(ii).det_well,...
                    'bead_batch', plateinfo.bead_batch,...
                    'bset_revision', plateinfo.bset_revision);
                smdict(detwells{jj}) = vals;
            end
        end
    otherwise
        error('Unknown mapversion')
end
