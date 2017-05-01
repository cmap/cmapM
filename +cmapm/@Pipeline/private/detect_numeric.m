function [desc, numeric] = detect_numeric(desc)
% detect numeric fields and convert them
% nanidx = cell2mat(cellfun(@(x) any(isnan(x)), desc, 'uniformoutput', false));
nanidx = strcmpi('NaN', desc);
desc(nanidx) = {'-666'};
[nr, nc] = size(desc);
numeric = false(nc, 1);
if nr>0
    % sample 10% of the rows to determine the type
    isnum = find(all(~isnan(str2double(desc(randsample(nr, floor(nr/20)+1), :))), 1));
    numeric(isnum) = true;
    if any(isnum)
        newdesc = num2cell(str2double(desc(:, isnum)));        
        % check if conversion is valid and revert to original if not
        nancel = cell2mat(cellfun(@(x) any(isnan(x)), newdesc, 'uniformoutput', false));
        [~, ic] = find(nancel);
        not_numeric = unique(ic);
        newdesc(:, not_numeric) = desc(:, isnum(not_numeric));        
        
        desc(:, isnum) = newdesc;
        numeric(not_numeric) = false;      
    end
    desc(nanidx) = {NaN};
end
end
