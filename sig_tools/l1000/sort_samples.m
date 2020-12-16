function [ds, cidx] = sort_samples(ds, varargin)
% SORT_SAMPLE Sort dataset columns.
% SRTDS = SORT_SAMPLES(DS) where DS is a dataset with the following column
% descriptor fields:
% {'cell_id', 'pert_time', 'pert_desc' ,'pert_id'}

key = {'cell_id', 'pert_time', 'pert_desc' ,'pert_id'};
sort_order = [1, 1, 1, 1];

if all(ds.cdict.isKey(key))
    keyidx = cell2mat(ds.cdict.values(key));
    [~, cidx] = sortrows(ds.cdesc, keyidx.*sort_order);
    ds = gctextract_tool(ds, 'cidx', cidx);
else
    fprintf('Not sorting samples\n');
    cidx = [];
end

end
