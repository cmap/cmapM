function st = get_linestyle(n, varargin)

% TODO fix cycling logic
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

pnames = {'attr', 'col', 'sym', 'dash'};
dflts = {'col,sym,dash', 'rgbck', 'oxs*^dv.', '-,--,:,-.'};
arg = parse_args(pnames, dflts, varargin{:});
vs = {'col','sym','dash'};
attr = unique_ord(tokenize(lower(arg.attr), ',', true));
if ~all(isvalidstr(attr, vs))
    error('Invalid attribute str %d. [Valid options: col,sym,dash]', arg.attr);
end
usecol = isvalidstr(vs{1}, attr);
usesymb = isvalidstr(vs{2}, attr);
usedash = isvalidstr(vs{3}, attr);

col = arg.col;
symb = arg.sym;
dash = tokenize(arg.dash,',');
ncol = usecol*(length(col));
nsymb = usesymb*length(symb);
ndash = usedash*length(dash);
nattr = length(attr);

nc = min(n, ncol);

if nc>0
    ns = min(ceil(n/nc), nsymb);
    if ns>0
        nd = min(ceil(n/(nc*ns)), ndash);
    else
        nd = min(n, ndash);
    end
else
    ns = min(n, nsymb);
    if ns>0
        nd = min(ceil(n/ns), ndash);
    else
        nd = min(n, ndash);
    end
end

st = cell(n,1);
is=min(1,ns);
ic=min(1,nc);
id=min(1,nd);
ia = 1;
lasta = 1;
st{1} = get_attr(ic, is, id, col, symb, dash);
for ii=2:n
    % fprintf ('Loop%d ic:%d is:%d id:%d ia:%d\n', ii, ic, is, id,ia)
    switch(attr{ia})
        case 'col'
            ic = mod(ic, ncol) + 1;
            if ic == 1
                ia = mod(ia+lasta-1, nattr)+1;
            elseif ia > 1
                lasta = ia;
                ia = 1;
            end
            
        case 'sym'
            is = mod(is, nsymb) + 1;
            if is == 1
                ia = mod(ia+lasta-1, nattr)+1;
            elseif ia > 1
                lasta = ia;
                ia =1;
            end
            
        case 'dash'
            id = mod(id, ndash) + 1;
            if id == 1
                ia = mod(ia+lasta-1, nattr)+1;
            elseif ia > 1
                lasta = ia;
                ia = 1;
            end
    end
    changed = ~isequal(ia, lasta);
    if changed
        switch(attr{ia})
            case 'col'
                ic = mod(ic, ncol) + 1;
                if ic == 1
                    ia = mod(ia+lasta-1, nattr)+1;
                elseif ia > 1
                    lasta = ia;
                    ia = 1;
                end
                
            case 'sym'
                is = mod(is, nsymb) + 1;
                if is == 1
                    ia = mod(ia+lasta-1, nattr)+1;
                elseif ia > 1
                    lasta = ia;
                    ia =1;
                end
                
            case 'dash'
                id = mod(id, ndash) + 1;
                if id == 1
                    ia = mod(ia+lasta-1, nattr)+1;
                elseif ia > 1
                    lasta = ia;
                    ia = 1;
                end
        end        
    end
    
    st{ii} = get_attr(ic, is, id, col, symb, dash);
    lasta = ia;
%     fprintf ('%d %s: ic:%d is:%d id:%d ia:%d lasta:%d\n', ii, st{ii}, ic, is, id, ia, lasta)
end

end

function style = get_attr(ic, is, id, col, symb, dash)
c = '';
s = '';
d = '';
if ic >0
    c = col(ic);
end
if is >0
    s = symb(is);
end
if id >0
    d = dash{id};
end

style = strcat(c,s,d);
end