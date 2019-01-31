function [dimstr, dimval] = get_dim2d(dim)
% GET_DIM2D Read dimension specified as a string or numerically
%   [S, V] = GET_DIM2D(D) D can be [1, 2] or 'row', 'column'. S and V are
%   corresponding string and numeric values
%
%   [S,V] = GET_DIM2D(1) % S='column', V=1
%   [S,V] = GET_DIM2D('row') % S='row', V=2

if strcmpi(dim, 'row') || isequal(dim, 2) || strcmp(dim, '2')
    dimstr = 'row';
    dimval = 2;
elseif strcmpi(dim, 'column') || isequal(dim, 1) || strcmp(dim, '1')
    dimstr = 'column';
    dimval = 1;
else
    error('Invalid dim expected either row|column or 1|2, got %s', stringify(dim));
end

end
