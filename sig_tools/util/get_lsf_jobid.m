function id = get_lsf_jobid
% GET_LSF_JOBID returns the LSF jobid
% Returns empty string if not executed via LSF

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

% [s, r] = system('echo $LSB_JOBID');
[~, r]=system('bash -c ''echo ${LSB_JOBID:-jobid}.${LSB_JOBINDEX:-jobindex}''');
r = strrep(r, 'jobid', '');
r = strrep(r, '.jobindex', '');
id = strtrim(r);
% check its a number
if isempty(id)
    id = '';
end
