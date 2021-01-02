function [tf, has_req_fn] = has_required_fields(s, req_fn, isverbose)
% HAS_REQUIRED_FIELDS Check if structure has required fields
%   YN = HAS_REQUIRED_FIELDS(S, F)
%   [YN, ISFN] = HAS_REQUIRED_FIELDS(S, F, ISVERBOSE)
%   YN = HAS_REQUIRED_FIELDS(S, F, ISVERBOSE)

if ~isvarexist('isverbose')
    isverbose = true;
end

has_req_fn = isfield(s, req_fn);
tf = all(has_req_fn);
if isverbose && ~tf    
    dbg(1, '%d/%d required fields missing',...
        nnz(has_req_fn), numel(has_req_fn));
    disp(req_fn(~has_req_fn))
end

end