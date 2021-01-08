function rpt = replicateStats(varargin)
% inputs 
%   sig_info with distil_id field
%   level4 matrix
%   row_space: lm

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    data_struct = loadData(args);
    rpt = computeStats(data_struct, args);    
else
    disp('help');
end

end

function rpt = computeStats(data_struct, args)

sig_id = {data_struct.sig_info.(args.sig_id_field)}';
replicates = {data_struct.sig_info.(args.replicate_field)}';
ngp = length(replicates);
rpt = struct('sig_id', sig_id,...
             'num_rep', nan,...
             'cc_q75', nan,...
             'cc_q75_unclipped', nan,...
             'cc_mom', nan);
nfeature = size(data_struct.ds.mat, 1);         
dbg(1, 'Computing statistics for %d replicate groups using %d features', ngp, nfeature);
for ii=1:ngp
    this_ds = ds_slice(data_struct.ds, 'cid', replicates{ii});
    nrep = size(this_ds.mat, 2);
    rpt(ii).num_rep = nrep;
    if nrep>1
        this_cc = ds_corr(this_ds, 'type', 'spearman');
        cc_vec = tri2vec(this_cc.mat, 1);
        cc_mat = set_diagonal(this_cc.mat, nan);
        cc_mom = nanmedian(nanmedian(clip(cc_mat, 0, inf)));
        
        rpt(ii).cc_q75 = q75(clip(cc_vec,0,inf));
        rpt(ii).cc_q75_unclipped = q75(cc_vec);
        rpt(ii).cc_mom = cc_mom;
    end
    
end
rpt = join_table(rpt, data_struct.sig_info, 'sig_id', args.sig_id_field);
end

function data_struct = loadData(args)

ds_annot = parse_gctx(args.ds);
sinfo = parse_record(args.sig_info);

if ~isfield(sinfo, args.replicate_field)
    error('replicate_field:%s not found in sig info', args.replicate_field);
end

if ~isfield(sinfo, args.sig_id_field)
    error('sig_id_field:%s not found in sig info', args.sig_id_field);
end

replicates = tokenize({sinfo.(args.replicate_field)}', '|');
sinfo = setarrayfield(sinfo, [], args.replicate_field, replicates);
all_replicates = unique(cat(1, replicates{:}));
is_rep_in_ds = ismember(all_replicates, ds_annot.cid);
if ~all(is_rep_in_ds)
    disp(all_replicates(~is_rep_in_ds));
    dbg(1, '%d replicate ids in sig_info not found in ds',...
        nnz(~is_rep_in_ds));
end
% row space
if ~isempty(args.rid)
    % custom space
    args.row_space = 'custom';
    rid =  parse_grp(args.rid);
elseif ~strcmpi(args.row_space, 'all')
    % pre-defined row_space
    is_valid_row_space = mortar.common.Spaces.probe_space.isKey(args.row_space);
    assert(is_valid_row_space, 'Invalid row space %s', args.row_space);
    rid = mortar.common.Spaces.probe(args.row_space).asCell;
else
    % default to all
    rid = '';
end
ds = parse_gctx(args.ds, 'rid', rid,...
                'row_filter', args.row_filter,...
                'column_filter', args.column_filter);
data_struct = struct('ds', ds, 'sig_info', sinfo);

end

function [args, help_flag] = getArgs(varargin)
scriptName = mfilename;        
className = mfilename('class'); 
fullName = sprintf('%s.%s', className, scriptName);
configFile = mortar.util.File.getArgPath(scriptName, className);
opt = struct('prog', fullName, 'desc', '');
[args, help_flag] = mortar.common.ArgParse.getArgs(configFile, opt, varargin{:});

end
