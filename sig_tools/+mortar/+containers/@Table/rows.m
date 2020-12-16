function r = rows(obj, ir)
% Row labels
if ~isempty(obj.row_)
    r = obj.row_.sortKeysOnValue;
    if nargin>1
        if obj.isValidIndex_(ir, 1)
            r = r(ir);
        else
            disp(ir)
            error('Invalid row index');
        end
    end
else
    r = {};
end

end