function saveSingleUnmatchedGutc(res, out_path)
% SAVESINGLEUNMATCHEDGUTC generate multi-resolution gutc dataset for
% one query
% SAVESINGLEUNMATCHEDGUTC(RES, OUT_PATH)

narginchk(2, 2);

if ~isdirexist(out_path)
    mkdir(out_path);
end

% must be a single query
assert(isequal(numel(res.cs.cid), 1));

% sig level
cs = ds_slice(res.cs, 'rid', res.ns.rid);
assert(isequal(res.ns.rid, res.rs.rid), 'Row order mismatch NS and RS');

sig = mkgctstruct([res.rs.mat, res.ns.mat, cs.mat], 'rid', cs.rid,...
                   'cid', {'percentile_score', 'norm_score', 'raw_score'},...
                   'chd', {'query_id'}, 'cdesc', [res.rs.cid; res.ns.cid; cs.cid]);
              
mkgct(fullfile(out_path,'sig.gct'), sig, 'appenddim', false);

% pert cell
mkgct(fullfile(out_path,'pert_cell.gct'), res.tpc, 'appenddim', false)              
% pert
mkgct(fullfile(out_path,'pert.gct'), res.tp, 'appenddim', false)              

end
