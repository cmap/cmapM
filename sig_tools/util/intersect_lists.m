function varargout = intersect_lists(l,fid)
% INTERSECT_LISTS Compute intersection of lists
% 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
nout = nargout;

printline=1;

if isequal(nout,1)

    printline=0;
    fid=1;
    
elseif ~exist('fid','var')

    fid=1;

end

if iscell(l)
    
    for ii=1:length(l)
        h{ii} = char(64+ii);
    end

elseif exist(l,'file')
    
    [h,l] = parse_tab_dlm(l);
    
end

nl = length(l);
ctr = nl+1;

result(1) = struct('name',h{1},'size',length(l{1}),'members','');
print_dlm_line({h{1},num2str(length(l{1}))},fid);

for ii=2:nl

    result(ii) = struct('name',h{ii},'size',length(l{ii}),'members','');
    print_dlm_line({h{ii},num2str(length(l{ii}))},fid);
    
    c = nchoosek(1:nl,ii);

    for jj=1:size(c,1)
        
        a = l{c(jj,1)};
        
        for kk=2:size(c,2)
            a = intersect(a, l{c(jj,kk)});             
        end
        if isnumeric(a(1))
            a=num2cellstr(a);
        end
        
        t = print_dlm_line(h(c(jj,:)),0,'_INTERSECT_');
        print_dlm_line({t,num2str(length(a)),print_dlm_line(a,0,',')},fid);
        result(ctr) = struct('name',t,'size',length(a),'members',print_dlm_line(a,0,','));
        ctr=ctr+1;
        
    end
    
    
end

if ~printline
    varargout(1) ={result};
end
