function wt = model2gct(fname)
% MODEL2GCT Get weight matrix from a model file.
%   WT = MODEL2GCT(FNAME) Load the model file FNAME in .mat format and
%   returns a GCT v2 structure WT.

if isfileexist(fname)
    load(fname)
    wt = mkgctstruct(model.wt, 'rid',model.rn, ...
        'cid',['OFFSET';model.cn], 'rhd',{'pr_gene'},...
        'rdesc',ps2genesym(model.rn), 'chd',{'pr_gene'},...
        'cdesc',['OFFSET'; ps2genesym(model.cn)]);
else
    error('File not found');
end
end