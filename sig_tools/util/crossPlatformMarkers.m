function mapping = crossPlatformMarkers(varargin)


toolName = mfilename ; 
pnames = {'-desc','-gct','-landmarks','-dependent'};%,'-out'};
dflts = {'','','',''};%,pwd};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 
% otherwkdir = mkworkfolder(arg.out,toolName); 
% fprintf('Saving analysis to %s\n',otherwkdir); 
% fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
% print_args(toolName,fid,arg); 
% fclose(fid); 


[~,gn,gd] = parse_gct0(arg.gct); 

fid = fopen(arg.desc,'r'); 
platformInfo = textscan(fid,repmat('%s',[1,6]),'Delimiter','\t',...
    'headerlines',1); 
fclose(fid); 


landmarks = parse_grp(arg.landmarks);
dep = parse_grp(arg.dependent);
[~,L] = intersect_ord(gn,landmarks);
[~,Ldep] = intersect_ord(gn,dep);
lgs = gd(L);
dgs = gd(Ldep) ;

old_mapping_landmarks = zeros(length(intersect(platformInfo{6},lgs)),1); 
old_mapping_dep = zeros(length(intersect(platformInfo{6},dgs)),1); 

flag_lgs = zeros(length(lgs),1); 
parfor i = 1 : length(lgs)
    if ~any(strcmp(lgs{i},platformInfo{6}))
        flag_lgs(i) = 1; 
    end
end
lgs(logical(flag_lgs))  = [];

parfor i = 1 : length(lgs)
    ix = find(strcmp(lgs{i},platformInfo{6})) ;
    old_mapping_landmarks(i) = ix(1) ; 
end

flag_dgs = zeros(length(dgs),1); 
parfor i = 1 : length(dgs)
    if ~any(strcmp(dgs{i},platformInfo{6}))
        flag_dgs(i) = 1; 
    end
end
dgs(logical(flag_dgs))  = [];

parfor i = 1 : length(dgs)
    ix = find(strcmp(dgs{i},platformInfo{6})) ; 
    old_mapping_dep(i) = ix(1) ; 
end

mapping.old_mapping_landmarks = old_mapping_landmarks; 
mapping.old_mapping_dep = old_mapping_dep ; 
mapping.existing_mapping_landmarks = gn(L(~logical(flag_lgs))); 
mapping.existing_mapping_dep = gn(Ldep(~logical(flag_dgs)));
mapping.existing_notfound_landmarks_gn = gn(L(logical(flag_lgs)));
mapping.existing_notfound_dep_gn = gn(Ldep(logical(flag_dgs)));
mapping.existing_notfound_landmarks_gd = gd(L(logical(flag_lgs)));
mapping.existing_notfound_dep_gd = gd(Ldep(logical(flag_dgs)));