function [isvalid, vp] = validate_path(s, rep)
%VALIDATE_FNAME Validate filename.
% [ISVALID, VF] = VALIDATE_FNAME(F) Checks if the string is a valid
% filename 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if (~exist('rep','var'))
    rep='';
end

[p,f,e] = fileparts(s);
vf = regexprep([f, e],...
    '(%|&|{|}|\s|+|!|@|#|\$|\^|*|\(|\)|=|\[|\]|\\|;|:|~|`|,|<|>|?|\/|"|\|\x22|\x27|\x7c)',...
    rep);

vf = regexprep(strsqueeze(vf, rep),[rep,'$'],'');

vp = regexprep(p,...
    '(%|&|{|}|+|!|@|#|\$|\^|*|\(|\)|=|\[|\]|;|:|~|`|,|<|>|?|"|\|\x22|\x27|\x7c)',...
    rep);

vp = fullfile(vp, vf);
isvalid = isequal(vp, s);
