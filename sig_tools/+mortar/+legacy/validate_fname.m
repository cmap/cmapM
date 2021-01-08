%VALIDATE_FNAME Validate filename.
% [ISVALID, VF] = VALIDATE_FNAME(F) Checks if the string is a valid
% filename 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [isvalid, vf] = validate_fname(s, rep)

if (~exist('rep','var'))
    rep='';
end
[p,f,e]=fileparts(s);

vf = regexprep([f,e], '(%|&|{|}|\s|+|!|@|#|\$|\^|*|\(|\)|=|\[|\]|\\|;|:|~|`|,|<|>|?|\/|"|\|\x22|\x27|\x7c)',rep);
vf = fullfile(p, vf);
isvalid = isequal(vf,s);
