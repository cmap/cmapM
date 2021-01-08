function mkbiomarked_gct(varargin)

toolName = mfilename ; 
pnames = {'-gct','-cls','-out','-num_markers'};
dflts = {'','',pwd,50};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out,toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

[ge,gn,gd,sid] = parse_gct0(arg.gct); 
cls.labels = parse_cls(arg.cls); 
cls.num_classes = length(unique(cls.labels)); 

markers = conbiomarker(ge',cls,arg.num_markers); 
close all ; 

mkgct0(fullfile(arg.out,horzcat(pullname(arg.gct),'_',...
    num2str(arg.num_markers),'-biomarked.gct')),ge(markers,:),gn,gd,sid,4); 