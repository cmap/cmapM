% identifies controls in ds GCT
% returns array of perturbation types
% pert_type = identify_ctl(ds,hd,varargin)
% hd - string, column header containing perturbations 
% 'ctrl_type' - cell array of strings
% 'ctrl_grps' - cell array, members are sets of perturbations corresponding
% to 'ctrl_type'
% 'gmt' - gmt file of sets of perturbations, can be used instead of
% 'ctrl_type' and 'ctrl_grps'
function pert_type = identify_ctl(ds,hd,varargin)

pnames = {'ctrl_type','ctrl_grps',...
    'gmt'};
dflts = {{''},{''},...
    struct([])};
args = parse_args(pnames, dflts, varargin{:});

if ~ds.cdict.isKey(hd)
    error('Invalid header: %s',hd);
end

if ~isempty(args.gmt)
    gmt = parse_gmt(args.gmt);
    args.ctrl_type = {gmt.head};
    args.ctrl_grps = {gmt.entry};
end

if length(args.ctrl_type)~=length(args.ctrl_grps)
    error('Dimension mismatch: %d ctrl_type ~= %d ctrl_grps',length(args.ctrl_type),length(args.ctrl_ids));
end

pert = ds.cdesc(:,ds.cdict(hd));

pert_type = repmat({'trt_cp'},[length(pert) 1]);

for i=1:length(args.ctrl_type)
    pert_type(ismember(pert,args.ctrl_grps{i})) = args.ctrl_type(i);
end
