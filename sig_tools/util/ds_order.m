function ds = ds_order(ds, dim, order_idx)
% DS_ORDER Custom re-order the rows or columns of a dataset
%
% DS_ORD = DS_ORDER(DS, DIM, ORDER_IDX) reorder dataset DS along DIM using
% the indices ORDER_IDX. If DIM is 'column' the rows are re-ordered else if
% DIM is 'row' the columns are re-ordered. ORDER_IDX is a permutation of
% 1:N where N is the number of elements in the dataset along the dimension
% of interest (e.g. if DIM='column' then N = size(DS.mat, 1) or the number
% of rows in DS). DS_ORD is the re-ordered dataset


dim_str = get_dim2d(dim);
switch lower(dim_str)
    case 'column'
        %validate order_idx
        n = length(ds.rid);
        validate_order(order_idx,n);
        
        ds.rid = ds.rid(order_idx);
        ds.mat = ds.mat(order_idx,:);
        
        %only reorder meta data if there is metadata
        if ~isempty(ds.rhd)
            ds.rdesc = ds.rdesc(order_idx,:);
        end
        
    case 'row'
        %validate order_idx
        n = length(ds.cid);
        validate_order(order_idx,n)

        ds.cid = ds.cid(order_idx);
        ds.mat = ds.mat(:,order_idx);
        
        %only reorder meta data if there is metadata
        if ~isempty(ds.chd)
            ds.cdesc = ds.cdesc(order_idx,:);
        end
        
    otherwise
        disp('Invalid dimension! Must be either "row" or "column"')
end
        
end

function validate_order(order_idx,n)
%returns true if order_idx is a permutation of 1:n and false otherwise
%
%needs to be able to handle order_idx as a row or a column vector

if length(order_idx) ~= n
    is_valid = false;
else
    temp_idx = reshape(order_idx,[1,n]);
    is_valid = isequal(sort(temp_idx),1:n);
end

error_str = sprintf('Invalid order_idx, must be a permutation of 1:%d',n);
assert(is_valid,error_str);

end
