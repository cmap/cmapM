function ex = parse_exp(expFile, sins)
% PARSE_EXP Parse .exp files
% EX = PARSE_EXP(EXPFILE, SINFILE Returns a nested structure EX of
% 
% EX = PARSE_EXP(EXPFILE, SINSTRUCT)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

ex = parse_gmx(expFile);


if ~isstruct(sins)
    sins = parse_sin(sins);
end

nq = length(ex);

for ii=1:nq

    [ex(ii).instance, ex(ii).instlen, ex(ii).instlabel, ex(ii).instdrug, ex(ii).instcell ] = find_sin(sins,ex(ii).entry);

end



