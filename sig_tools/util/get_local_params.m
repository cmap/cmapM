function [local_pv, pvpairs] = get_local_params(pvpairs, pnames)
% GET_LOCAL_PARAMS Get indices of specified parameters.

n = length(pvpairs);
idx = false(1,n);
for ii=1:n
    if any(strcmp(pnames, pvpairs(ii)))
        idx (ii)= true;
    end
end
idx = find(idx);
local_idx  = reshape([idx;idx+1], length(idx)*2, 1);
local_pv = pvpairs(local_idx);
pvpairs(local_idx) = [];

end