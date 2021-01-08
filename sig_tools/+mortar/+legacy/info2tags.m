% INFO2TAGS Convert info structure to luminex tag string
% T = INFO2TAGS(S)

function t = info2tags(s)

name = fieldnames(s);
% ignore 'name'
print_name = regexprep(name,'^name$','');

nf = length(name);
t=[];
dlm='|';

for ii=1:nf
    if ii==nf
        dlm='';
    end
    if isempty(print_name{ii})
        t = strcat(t, s.(name{ii}), dlm);
    else        
        t = strcat(t,sprintf('%s=', print_name{ii}), s.(name{ii}), dlm);
    end
    
end