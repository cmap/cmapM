function c = columns(obj, ic)
% Columns labels
if ~isempty(obj.col_)
    c = obj.col_.sortKeysOnValue;
    if nargin>1
        if obj.isValidIndex_(ic, 2)
            c = c(ic);
        else
            disp(ic)
            error('Invalid column index');
        end
    end
else
    c = {};
end
end