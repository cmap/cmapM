function gct2mat(varargin)

toolName = mfilename ; 
dflt_out = get_lsf_submit_dir ; 
pnames = {'-gct','-out'};
dflts = {'',dflt_out};
arg = parse_args(pnames,dflts,varargin{:}); 
print_args(toolName,1,arg); 

[ge,gn,gd,sid] = parse_gct0(arg.gct); 

ge = double(ge); 

fprintf(1,'%s\n',horzcat('Saving mat conversion to ',...
    fullfile(arg.out,pullname(arg.gct))))
save(fullfile(arg.out,pullname(arg.gct)),'ge','gn','gd','sid') ;