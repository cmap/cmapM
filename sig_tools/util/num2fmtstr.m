function s = num2fmtstr(n)
% NUM2FMTSTR Returns formated strings of decimal numbers.
%   S = NUM2GMTSTR(N) returns a comma separated string S of a number N. N
%   can be a scalar or array. S is a cell array if N is an array.

assert(isnumeric(n), 'Input should be numeric');


obj = java.text.DecimalFormat;
nel = length(n);

s = cell(nel, 1);
for ii=1:nel
    s{ii} = char(obj.format(n(ii)));
end

if isequal(nel, 1)
    s = s{1};
end

end