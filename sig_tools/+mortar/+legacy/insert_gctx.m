function insert_gctx(dsfile, ds, varargin)
error(nargchk(2, 4, naragin))

annot = parse_gctx(dsfile, 'annot_only', true);
ds = gctextract_tool(ds, 'rid', annot.rid);
[~, cidx] = setdiff(ds.cid, annot.cid);
ncid = length(cidx);
if ~isequal(length(cidx), ncid)
    cmn = intersect(ds.cid, annot.cid);
    disp(cmn);
    warn('%d samples already exist in dsfile, skipping', length(cmn))
    % keep only the unique cids
    ds = gctextract_tool(ds, 'cid', ds.cid(cidx));
end


%file = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
% append matrix
% write annot


end