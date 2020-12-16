function [y, iy] = get_topn(x, n, dim, direc, is_two_tailed)
% GET_TOPN Get top N elements from a sorted matrix
% [Y, IY] = GET_TOPN(X, N, DIM, DIREC, IS_TWO_TAILED) returns the top N
% elements from X after sorting in the DIREC order along dimension DIM. If
% IS_TWO_TAILED is true then both the top and bottom N values are returned.
% Important: This method ignores NaN values in X, but can produce overlapping
% values in Y when N is greater than the number of non-missing values

dim_str = get_dim2d(dim);

if isequal(dim_str, 'row')
    x = x';
    by_row = true;
else
    by_row = false;
end

[nr, nc] = size(x);

if is_two_tailed
    topick = min(n, floor(nr/2));
    if topick<n
        warning('N exceeds the number of elements, setting to: %d', topick);
    end
    if strcmpi(direc, 'descend')
        bot_direc = 'ascend';
    else
        bot_direc = 'descend';
    end
        
    [y_top, iy_top] = get_topn_core(x, topick, direc, by_row);
    [y_bot, iy_bot] = get_topn_core(x, topick, bot_direc, by_row);
    if by_row
        y = [y_top, fliplr(y_bot)];
        iy = [iy_top, fliplr(iy_bot)];
    else
        y = [y_top; flipud(y_bot)];
        iy = [iy_top; flipud(iy_bot)];
    end
else
    topick = min(n, nr);
    if topick<n
        warning('N exceeds the number of elements, setting to: %d', topick);
    end
    [y, iy] = get_topn_core(x, topick, direc, by_row);
end

end


function [y, iy] = get_topn_core(x, topick, direc, by_row)
[nr, nc] = size(x);
[srtx, isrt] = sort(x, 1);
if strcmpi(direc, 'descend')
    isrt = flipud(isrt);
    srtx = flipud(srtx);
end
% pad sorted matrix with a dummy row to handle missing values
srtx_padded = [srtx; nan(1, nc)];
[firstr, ic] = first_nonzero(~isnan(srtx));
% row indices, clip indices to dummy row
ir = min(bsxfun(@plus, firstr', (0:topick-1)'), nr+1);
iyp = bsxfun(@plus, ir, (0:nc-1)*(nr+1));
y = srtx_padded(iyp);
% indices for unsorted x
if by_row
    icol = isrt(bsxfun(@plus, min(ir, nr), (0:nc-1)*nr));
    iy = bsxfun(@plus, 1:nc, (icol-1)*nc)';
    y = y';
else
    irow = isrt(bsxfun(@plus, min(ir, nr), (0:nc-1)*nr));
    iy = bsxfun(@plus, irow, (0:nc-1)*nr);
end

end