% INFO2TAGS Convert info structure to luminex tag string
% T = INFO2TAGS(S)

function t = dict2tags(s)

name = s.keys;
% ignore 'name'
%print_name = regexprep(name,'^name$','');

nf = length(name);
t=[];
dlm='|';

for ii=1:nf
    if ii==nf
        dlm='';
    end
    t = strcat(t,sprintf('%s=', name{ii}), stringify(s(name{ii})), dlm);    
end