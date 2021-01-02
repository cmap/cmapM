function news = add_filedim(s, nrow, ncol)
% Add dimensions to filename
%  T = ADD_FILEDIM(S, NR) Appends number of rows to S such that:
%   ADD_FILEDIM('file', 123) = file_n123
%   ADD_FILEDIM('file', 123, 10) = file_n10x123

nin = nargin;
narginchk(2, 3);
news = rm_filedim(s);

if nin >2
    news = sprintf('%s_n%dx%d', news, ncol, nrow);
elseif nin>1
    news = sprintf('%s_n%d', news, nrow);
else
    error('Dimensions not specified');
end

end