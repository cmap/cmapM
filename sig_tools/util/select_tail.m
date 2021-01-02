function select_idx = select_tail(max_n, n)
% SELECT_TAIL Generate top and bottom N indices for a list of length
% MAX_N.
tail_size = min(max_n/2, n);
if tail_size>1
    select_idx = [1:ceil(tail_size), ceil(max_n-tail_size+1):max_n];
else
    select_idx = [];
end
