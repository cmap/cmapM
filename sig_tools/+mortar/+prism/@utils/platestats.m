% makes report of plate stats
% tbl = platestats(plates_mfi, mfi_dir, plates_count, count_dir,varargin)
% Arguments:
%	plates_mfi: cell array of strings, MFI GCTs
%   mfi_dir: 'mfi/gcts', directory containing MFI GCTs
%	plates_count: cell array of strings, bead count GCTs
%   count_dir: 'bead/count/gcts', directory containing bead count GCTs
%	'out': 'print/report/here', directory to save reports, default '.'
%	'rpt': filename of report, default 'rpt.txt'
%   'platerpt': whether to print reports for individual plates, default
%   false

function tbl = platestats(plates_mfi, mfi_dir, plates_count, count_dir,varargin)

pnames = {'out','rpt','platerpt'};
dflts = {'.','rpt.txt',false};
args = parse_args(pnames, dflts, varargin{:});

if ~isfileexist(args.out,'dir')
	error('Output directory %s does not exist', args.out);
end

if length(plates_mfi)==length(plates_count)
	x = regexprep(plates_mfi,{'\w*/','.gct','median_'},'');
	y = regexprep(plates_count,{'\w*/','.gct','count_'},'');
	if prod(strcmp(x,y))==0
		error('MFI and bead count plates must match in order and ID');
	end
else
	error('Number of plates must be the same');	
end

n = length(plates_mfi);
  
count_med = cell([1 n]);
count_cv = cell([1 n]);
veh_ctrl_cv = cell([1 n]);
pc_cv = cell([1 n]);
nd_cv = cell([1 n]);
pc_corr = cell([1 n]);


%% this section may change - dependent on naming scheme of data
%compound plate
cpplate = regexp([plates_mfi{:}],'ROC[0-9]{3}','match');
%beadset
bset = regexp([plates_mfi{:}],'B.[A-Z]{4}','match');
%replicate
rep = regexp([plates_mfi{:}],'X[0-9]','match');
%report ids
rpt = strcat(cpplate,'_',bset,'_',rep);

%% plate stats
for p=1:n

	[~,ds] = evalc('parse_gct(fullfile(mfi_dir,plates_mfi{p}));');
	[~,dsct] = evalc('parse_gct(fullfile(count_dir,plates_count{p}));');
	
	% plate count cv
	wellcnt = nanmedian(dsct.mat);
	count_med{p} = median(wellcnt);
	count_cv{p} = 100*iqr(wellcnt)/count_med{p};
	
	% veh ctrl cv
	ptype = ds.cdesc(:,ds.cdict('pert_type'));
	ind = ismember(ptype,'veh_con');
	veh_ctrl_med = median(ds.mat(:,ind));
	veh_ctrl_cv{p} = 100*iqr(veh_ctrl_med)/median(veh_ctrl_med);
	
	% pos con cv
	ind = ismember(ptype,'pos_con');
	pc_med = median(ds.mat(:,ind));
	pc_cv{p} = 100*iqr(pc_med)/median(pc_med);
	
	% no dna cv
	ind = ismember(ptype,'nodna');
	nd_med = median(ds.mat(:,ind));
	nd_cv{p} = 100*iqr(nd_med)/median(nd_med);
	
	% dox/etop corr
	cpd = ds.cdesc(:,ds.cdict('compound'));
	etop_ind = ismember(cpd,'Etoposide');
	dox_ind = ismember(cpd,'Doxorubicin');
	etop = ds.mat(:,etop_ind);
	etop = etop(:);
	dox = ds.mat(:,dox_ind);
	dox = dox(:);
	pc_corr{p} = corr(dox,etop,'rows','complete');
    
    if args.platerpt
        s = struct('plate',rpt{p},'plate_med', plate_med{p}, 'plate_cv', plate_cv{p}, 'veh_ctrl_cv',...
            veh_ctrl_cv{p}, 'pc_cv', pc_cv{p}, 'nd_cv', nd_cv{p},'pc_corr', pc_corr{p});
        T = evalc('mktbl(fullfile(args.out,strcat(rpt{p},''.txt'')),s);');
    end
	
end

%print plate report
tbl = struct('plate',rpt,'count_med', count_med, 'count_cv', count_cv, 'veh_ctrl_cv',...
veh_ctrl_cv, 'pc_cv', pc_cv, 'nd_cv', nd_cv,'pc_corr', pc_corr);
mktbl(fullfile(args.out,args.rpt),tbl);
