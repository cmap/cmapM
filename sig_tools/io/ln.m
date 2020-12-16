function status = ln(src, dest, issoft)
% LN Create a link to a file.
% STATUS = LN(SRC, DEST, ISSOFT)

if nargin >2
    issoft = logical(issoft);
else
    issoft = false;
end
if issoft
    status = system(sprintf('ln -s %s %s', src, dest));
else
    status = system(sprintf('ln %s %s', src, dest));
end

end
