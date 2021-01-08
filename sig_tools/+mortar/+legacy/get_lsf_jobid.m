% GET_LSF_JOBID returns the LSF jobid
% Returns empty string if not executed via LSF

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function id = get_lsf_jobid

[s, r] = system('echo $LSB_JOBID');
id = strtrim(r);
% check its a number
if isnan(str2double(id))
    id = '';
end
