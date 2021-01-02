function [has_maj, maj_val] = boyer_more(x)
% BOYER_MORE find the majority value in a list if it exists
x = x(:);
nx = length(x);
value = 0;
count = 0;
for ii=1:nx
    if count == 0
        value = x(ii);
        count = count +1;
    end
    if value ~= x(ii)
        count = count - 1;
    end
end
has_maj = nnz(abs(x - value)<eps) > nx/2;
if has_maj
    maj_val = value;
else
    maj_val = nan;
end

end