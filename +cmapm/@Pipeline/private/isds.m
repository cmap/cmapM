function tf = isds(x)
% Check if a structure is a valid dataset

tf = isstruct(x) && all(ismember({'mat','rid','cid','rdesc',...
                    'cdesc','chd','rhd','rdict',...
                    'cdict','src'}, fieldnames(x)));
end