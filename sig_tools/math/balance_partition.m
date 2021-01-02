function [a,b] = balance_partition(n)
%Given an integer n, returns integers a,b such that
%
%1. a*b > n
%2. a*b \approx n
%3. a \approx b
%4. a <= b
%
%This function is useful for use with subplot, when the number of subplots
%is not known a priori.

s = sqrt(n);

if floor(s)*ceil(s) >= n
    a = floor(s);
    b = ceil(s);
else
    a = ceil(s);
    b = ceil(s);
end

end

