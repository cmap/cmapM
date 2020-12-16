function tf = isgeneset(x)
% ISGENESET Check if a structure is a valid geneset
% TF = ISGENESET(X)

tf = isstruct(x) &&...
     all(ismember({'head', 'desc', 'len', 'entry'}, fieldnames(x)));
end