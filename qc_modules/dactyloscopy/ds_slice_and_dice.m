function [ds_plate_out,ds_ref_out,lincs_lines_out,lm_probes_present] = ...
    ds_slice_and_dice(ds_plate, ds_ref, lincs_lines, lm_probes)
%% Function that slices a gct files of the reference libarary and of the plate
%  to match the number of features, in case the number of landmark genese
%  is different in these two gct files.
%
% E-mail: Marek Orzechowski morzech@broadinstitute.org
fprintf('%s> Running ds_slice_and dice for: %s and %s\n',...
    mfilename,inputname(1),inputname(2))

%% Check if all the LINCS cell lines are in the reference library
ll_present = ismember(lincs_lines, ds_ref.cid);
ll_missing = ~ismember(lincs_lines, ds_ref.cid);
if sum(ll_missing)>0
    fprintf('%s> The following %d LINCS lines are missing from the reference library:\n',...
        mfilename, sum(ll_missing))
    disp(lincs_lines(ll_missing))
end
lincs_lines_out = lincs_lines(ll_present);

%% Check if all the landmark probes are in the reference library
lm_probes_missing_ref = lm_probes(~ismember(lm_probes,ds_ref.rid));
lm_probes_present_ref = lm_probes(ismember(lm_probes,ds_ref.rid));

%% Check if there are any missing landmark probes from the plate
lm_probes_missing_plate = lm_probes(~ismember(lm_probes,ds_plate.rid));
lm_probes_present_plate = lm_probes(ismember(lm_probes,ds_plate.rid));

%% Get intersection of landmark probes present in the reference library and in the plate
lm_probes_present = intersect(lm_probes_present_ref, lm_probes_present_plate);
lm_probes_missing = setdiff(lm_probes,lm_probes_present);

%% Slice and dice the refrence libraries
% Sometimes not all the landmark genes (probes) are present in the reference
% library so get the intersection
% Consider using a list of genes from /cmap/data/vdb/spaces/lm_epsilon_n978.grp
%
% present_lm = ismember(lm_probes,ds_plate.rid);
% if sum(present_lm)~=978
%     warning('%s> Some of the landmark genes were missing', mfilename)
%     lm_probes = lm_probes(present_lm);
% end

% Slice gct structures to take only landmark genes (or whatever subset of
% lm genes was found in ds_plate; see above)

ds_ref_out = ds_slice(ds_ref,'rid',lm_probes_present);
number_missing_lm = length(lm_probes) - length(lm_probes_present);

if number_missing_lm>0
    fprintf('%s> Some of the landmark genes (%d) were not found in the reference library\n',...
        mfilename, number_missing_lm)
    disp(lm_probes_missing)
end
% Slice ds_plate again to match the features with the reference library
ds_plate_out = ds_slice(ds_plate,'rid',lm_probes_present);
fprintf('%s> The final number of features is %d\n\n',mfilename,length(lm_probes_present))