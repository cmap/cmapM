function [ok] = checkcas(cas)
% CHECKCAS Check digit verification of CAS numbers.
% [OK] = CHECKCAS(CAS) Verifies each number in CAS (a string or cell array)
% and returns a binary vector OK indicating if each number is valid.
% See: http://www.cas.org/expertise/cascontent/registry/checkdig.html
if nargin && ~isempty(cas)
    if ischar(cas)
        cas = {cas};
    end
    n=length(cas);
    ok = zeros(n,1);
    cleancas = regexprep(cas,'-','');
    
    for ii=1:n
        N = str2double(cleancas(1:end-1)');
        R = str2double(cleancas(end));
        checksum = sum((length(N):-1:1)'.*N)/10;
        rem = 10*(checksum - floor(checksum));
        if (rem-R)<=eps
            ok(ii) = 1;
        end
    end
end