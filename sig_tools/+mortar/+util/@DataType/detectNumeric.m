function [desc, is_numeric] = detectNumeric(desc)
% detectNumeric detect numeric fields and convert them

nanidx = strcmpi('NaN', desc);
if nnz(nanidx)
    desc(nanidx) = {'-666'};
end
[nr, nc] = size(desc);
is_numeric = false(nc, 1);
if nr>0       
    % sample 5% of the rows to determine the type
    isnum = find(all(~isnan(str2double(desc(...
                randsample(nr, floor(nr*0.20)+1), :))), 1));
    is_numeric(isnum) = true;
    if any(isnum)
        newdesc = num2cell(str2double(desc(:, isnum)));        
        % check if conversion is valid and revert to original if not
        nancel = cell2mat(cellfun(@(x) any(isnan(x)), newdesc,...
                    'uniformoutput', false));
        [~, ic] = find(nancel);
        not_numeric = unique(ic);
        newdesc(:, not_numeric) = desc(:, isnum(not_numeric));        
        
        desc(:, isnum) = newdesc;
        is_numeric(not_numeric) = false;      
    end
    if nnz(nanidx)
        desc(nanidx) = {NaN};
    end
end
end