function calibds  = gen_calib_matrix(gmxFile, ds)
% GEN_CALIB_MATRIX Generate expression matrix of L-1000 calibration genes
% [cm,cn,cd, sid]  = gen_calib_matrix(gmxFile, gctFile)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

% gmx struct: name, desc, len,
if isstruct(gmxFile)
    gmx=gmxFile;
elseif isfileexist(gmxFile)
    gmx = parse_gmx(gmxFile);
else
    error('gmxFile:%s notfound',gmxFile);
end

% ds can be a file or gct struct
if ~isstruct(ds) && isfileexist(ds)
    ds = parse_gct(ds);
elseif ischar(ds)
    error('gctFile:%s notfound', ds);
end

nCalib = length(gmx);
nSample = size(ds.mat,2);

cm = zeros(nCalib, nSample);
cn = cell(nCalib,1);
cd = cell(nCalib,1);

for ii=1:nCalib
    [c,idx] = intersect_ord(ds.rid, gmx(ii).entry);
    if isempty(idx)
        error ('No calib genes found at level %d\n',ii);
    elseif ~isequal(length(idx), gmx(ii).len)
        fprintf ('Warning: Some genes not found at level %d\n',ii);
        disp(setdiff(gmx(ii).entry, c));
    end    
    cm(ii,:) = max(nanmedian(ds.mat(idx,:), 1), 0);
    cn{ii} = gmx(ii).head;
    cd{ii} = gmx(ii).desc;
end

calibds = mkgctstruct(cm, 'rid', cn, 'rhd', {'desc'}, 'rdesc', cd,...
    'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc);
