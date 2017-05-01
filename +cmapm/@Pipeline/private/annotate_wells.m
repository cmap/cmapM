function ds = annotate_wells(ds, plateinfo, varargin)
% called from qc_pipe and dpeak_pipe annotates the ds structure and
% extracts wells from dscnt if asked for does not add any annotations to
% the dscnt structure; don't need them 
% Inputs:
%   gct-like structure ds and dscnt (the expression and count .csv's) A map
%   file
% Outputs: .gct structures for expression and count, with annotated wells
% Optional argument: incomplete_map When set to true, wells not present in
% the .map file are extracted from the .gct If false, will fail if the
% number of wells in the ds does not match the map file. 
% DW, Jan. 2012

pnames = {'incomplete_map'};
dflts = {true};
arg = parse_args(pnames, dflts, varargin{:});
% get the wells from the .map file and the .csv
welldict = map_samples(plateinfo.local_map, plateinfo, varargin{:}); 
[wells, word] = get_wellinfo(ds.cid);

% if the users specifies an incomplete .map file, extract the required wells
if arg.incomplete_map && ~isequal(length(wells), welldict.length)
    % the indices from ds.cid to keep
    [~,~,keepidx] = intersect_ord(keys(welldict), wells); 
    % extract the correct wells
    ds = gctextract_tool(ds, 'cid', ds.cid(keepidx)); 
    % get the wells again; only the extracted ones
    [wells, word] = get_wellinfo(ds.cid); 
end

% make well annotations
vals = welldict.values(wells);
ds.well = wells;
ds.cid = cellfun(@(x) x.det_name, vals, 'uniformoutput', false);
% descriptor dict for each well (one dict per well)
well_desc = cellfun(@(x) x.sm_desc, vals, 'uniformoutput', false);
% merge into one dictionary
combodict = merge_celldict(well_desc);
ds.chd = combodict.keys;
ds.cdict = list2dict(ds.chd);
nmeta = length(ds.chd);
ds.cdesc = cell(length(wells), nmeta);
for ii=1:nmeta
    ds.cdesc(:,ii) = combodict(ds.chd{ii});
end

% extra steps if called from dpeak
ds.profname = cellfun(@(x) x.prof_name, vals, 'uniformoutput', false);
% beadset info
ds.bset = cellfun(@(x) x.bset, vals, 'uniformoutput', false);
