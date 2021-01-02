function lss_likelihood(varargin)
% LSS_LIKELIHOOD Compute likelihood of LSS within chemical sets
%
%   lss_likelihood(varargin) will compute a likelihood score for each
%   chemical set and biological target pair. The output is useful for
%   mining structure activity relationships given LSS values. High
%   likelihood implies encrichment of chemical set. Probability values per
%   feature within a chemical set are found via LSS ecdf lookup. The
%   probabilities in the likelihood product are cumulative probabilities.
%   Inputs: 
%       '-lss': the collapsed LSS values, a p-by-q matrix, p=# ligands, q=#
%       biological targets
%       '-gmx': the *gmx file which specifies chemical set membership
%       '-measure': used for debugging purposes, the product is
%       recommended, and is default
%       '-out': the output directory
%   Outputs:
%       The likelihood score matrix is outputted as a gct file, a b-by-q
%       matrix where b=# chemical sets in gmx
% 
% pnames = {'-lss','-gmx','-measure','-out'}; 
% dflts = {'','','prod',dflt_out};
%
% Author: Brian Geier, Broad 2010

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-lss','-gmx','-measure','-out'}; 
    
dflts = {'','','prod',dflt_out};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 
% 
otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

[lss,gn,~,sid] = parse_gct0(arg.lss); lss = double(lss); 

chem_sets = parse_gmx(arg.gmx); 
num_sets = length(chem_sets); 
num_classes = length(sid); 

lss_ll = zeros(num_sets,num_classes); 

isParallel = spopen();
chemset_idx = zeros(size(lss,1),num_sets); 
chemset_names = cell(num_sets,1); 
for i = 1 : num_sets
    [~,list] = intersect_ord(gn,chem_sets(i).entry); 
    if isempty(list)
        chemset_names{i} = dashit(chem_sets(i).head);
        continue
    elseif length(list) < 5
        chemset_names{i} = dashit(chem_sets(i).head);
        continue
    end
    chemset_idx(list,i) = 1;
    chemset_names{i} = dashit(chem_sets(i).head); 
end
chemset_idx = logical(chemset_idx) ; 

% h = waitbar(0,'Please wait... computing likelihoods');
for i = 1 : num_classes
    lss_ll(:,i) = compute_ll(chemset_idx,lss(:,i),isParallel,arg.measure) ; 
%     waitbar(i/num_classes,h); 
   
    % .. computation , for each class, for each set find p-value product
end
% close(h); 

mkgct0(fullfile(arg.out,[pullname(arg.lss),'_el.gct']),lss_ll,...
    chemset_names,chemset_names,sid,8); 
    
end

function ll = compute_ll(chem_sets,lss,isParallel,measure) 
% chem_sets is a sparse binary matrix, indicating membership

num_sets = size(chem_sets,2); 
ll = zeros(num_sets,1); 
p = size(chem_sets,1); 
if isParallel
    parfor i = 1 : num_sets
        if all(~chem_sets(:,i))
            continue
        end
        switch measure
            case 'prod'
                ll(i) = prod(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'median'
                ll(i) = median(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'mean'
                ll(i) = mean(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'prod-root'
                ll(i) = (prod(getpvalue(lss,lss(chem_sets(:,i))))) ...
                    .^(1/sum(chem_sets(:,i)));
            case 'prod-weighted'
                ll(i) = (prod(getpvalue(lss,lss(chem_sets(:,i))))) ...
                    .*(sum(chem_sets(:,i))/p) ; 
            otherwise
                error('unsupported measure..'); 
        end
                
    end
else
    for i = 1 : num_sets
        if all(~chem_sets(:,i))
            continue
        end
        switch measure
            case 'prod'
                ll(i) = prod(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'median'
                ll(i) = median(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'mean'
                ll(i) = mean(getpvalue(lss,lss(chem_sets(:,i)))) ; 
            case 'prod-root'
                ll(i) = (prod(getpvalue(lss,lss(chem_sets(:,i))))) ...
                    .^(1/sum(chem_sets(:,i)));
            case 'prod-weighted'
                ll(i) = (prod(getpvalue(lss,lss(chem_sets(:,i))))) ...
                    .*(sum(chem_sets(:,i))/p) ;
            otherwise
                error('unsupported measure..'); 
        end 
    end
end

end
    