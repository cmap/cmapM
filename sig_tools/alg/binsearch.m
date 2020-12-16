% BINSEARCH Perform a binary search in a sorted list of values.
% IDX = BINSEARCH (A, VALUE, LOW, HIGH) search sorted array A for VALUE and
% returns the index if found or -1 if not found.
% IDX = BINSEARCH (A, VALUE, LOW, HIGH, MODE) where MODE is a string which
% can be one of ['eq', 'gte', 'lte', 'gt', 'lt']

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function idx = binsearch(A, value, low, high, mode) 

if ~exist('mode', 'var')
    mode = 'eq';
end

mid = int32(low + ((high - low) / 2));  % Note: not (low + high) / 2 !!

if (high < low)

    if isequal(mode,'eq') % value not found
        idx = -1; 
    elseif isequal(mode, 'gte') || isequal(mode, 'gt') % min index >= value
        idx = mid+1;  
    elseif isequal(mode, 'lte') || isequal(mode, 'lt') % max index <= value
        idx = mid; 
    end
    
    if ( idx < 1 || idx > length(A) )
        idx = -1;
    end    
    return
end
    
if (A(mid) > value)
    idx = binsearch(A, value, low, mid-1, mode);
elseif (A(mid) < value)
    idx = binsearch(A, value, mid+1, high, mode);
else
    % value found
    % for eq, gte, lte
    if isequal(mode, 'eq')||isequal(mode, 'gte')||isequal(mode, 'lte')
        idx = mid; 
    elseif isequal(mode, 'gt')
    % for gt
        idx = mid+1;
    % for lt
    else
        idx = mid -1;
    end
    % bounds check
    if ( idx < 1 || idx > length(A) )
        idx = -1;
    end    
end
