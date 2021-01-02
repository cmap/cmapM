function mkins(varargin) 
% pnames = {'-gct','-sdf','-out','-islog'}; 
dflt_out  = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-gct','-sdf','-out','-islog'}; 
dflts = {'','',dflt_out,0}; 

arg = parse_args(pnames,dflts,varargin{:});

print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out,toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

spopen ; 
sdf = parse_sdf(arg.sdf); 
[ge,gn,gd,sid] = parse_gct0(arg.gct); 
ins = zeros(size(ge,1),length(sdf));

check_txt = lower(sid{1}); 
if strcmp(check_txt(end-3:end),'.txt')
    for j = 1 : length(sid) 
        drop_txt = sid{j} ; 
        drop_txt(end-3:end) = [];
        sid{j} = drop_txt ; 
    end
end
% h = waitbar(0,'Computing instances...'); 
fprintf(1,'%s\n','Computing instances')
ins_sid = cell(length(sdf),1); 
islog = arg.islog; 

parfor i = 1 : length(sdf)
    ins_sid{i} = sdf(i).instance_id{1}; 
    [~,veh_ix] = intersect_ord(sid,sdf(i).veh_cell_fname) ; 
    [~,ins_ix] = intersect_ord(sid,sdf(i).ins_cell_fname) ; 
    if isempty(ins_ix)
%         error('check sdf')
        ins(:,i) = 0; 
        continue
    end
    if isempty(veh_ix)
%         error('check sdf')
        ins(:,i) = 0; 
        continue
    end
    ins(:,i) = compute_ins(ge(:,ins_ix),ge(:,veh_ix),islog,sdf(i).type); 
%     waitbar(i/length(sdf),h); 
end
% close(h); 

% [~,ins_ranks] = sort(ins,1,'descend'); 
ins_ranks = rankorder(ins,'direc','descend'); 
mkgct0(fullfile(otherwkdir,[pullname(arg.gct),'_ins_ratios.gct']),ins,gn,gd,ins_sid); 
mkgct0(fullfile(otherwkdir,[pullname(arg.gct),'_ins_ranks.gct']),ins_ranks,gn,gd,ins_sid); 

system(['cp ',fullfile(otherwkdir,[pullname(arg.gct),'_ins_ranks.gct']),' ',...
    arg.out]);