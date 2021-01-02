function [res, ia, ib] = setop(opfn, a, b)
    import mortar.legacy.*
    isnum = false;
    if iscellnum(a) && iscellnum(b)        
        isnum = true;
        a = cell2mat(a);
        b = cell2mat(b);        
    end
    
    switch opfn
        case {'intersect', 'union', 'setxor', 'mortar.legacy.intersect_ord'}
            [res, ia, ib] = feval(opfn, a, b);
        case 'setdiff'
            [res, ia] = feval(opfn, a, b);
        otherwise
            error('Unknown set operator : %s', opfn);
    end
    
    if isnum
        res = num2cell(res);
    end
end