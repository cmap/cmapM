function tf = isds(x)
% ISDS Check if a structure is a valid dataset
% TF = ISDS(X)

tf = isstruct(x) && all(ismember({'mat','rid','cid','rdesc',...
                    'cdesc','chd','rhd','rdict',...
                    'cdict','src'}, fieldnames(x)));
end