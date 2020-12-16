% CHLOGBASE Change base of the logarithm
% Y = CHLOGBASE(X, B1, B2) if X = Log_B1(Z) then Y = Log_B2(Z)
% CHLOGBASE(3, 10, 2) % returns log2(1000)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function y = chlogbase(x, b1, b2)

known_bases = [2, exp(1), 10];
logfn = {@log2, @log, @log10};
[cmn1, b1_idx] = intersect(known_bases, b1);

if ~isempty(cmn1)
    y = x./logfn{b1_idx}(b2);    
else
    y = log2(b1).*x./log2(b2);
end

