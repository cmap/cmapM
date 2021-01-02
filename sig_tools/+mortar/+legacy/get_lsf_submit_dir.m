% GET_LSF_SUBMIT_DIR Returns the submit folder 
% for LSF jobs returns LS_SUBCWD else returns PWD

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function d = get_lsf_submit_dir

[s, d] = system('echo $LS_SUBCWD');
d=strtrim(d);

if isempty(d) || ~isdirexist(d)
 d = pwd;
end
