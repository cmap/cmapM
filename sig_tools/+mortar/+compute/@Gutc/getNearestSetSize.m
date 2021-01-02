function nearest_size = getNearestSetSize(ref_size, test_size)
% getNearestSetSize Find nearest reference size 
% N = getNearestSetSize(R, T) returns the nearest value in array R for each
% element in array T such that
%
% N(i) = R(min_idx)
% where [~, min_idx] = min(abs(R(:)-T(i))); 

[~, min_idx] = min(abs(bsxfun(@minus, ref_size(:)', test_size(:))), [], 2);
nearest_size = ref_size(min_idx);

end