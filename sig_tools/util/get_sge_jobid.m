function id = get_sge_jobid
% GET_SGE_JOBID returns the SGE jobid
% Returns empty string if not executed via SGE

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

[~, r]=system('bash -c ''echo ${JOB_ID:-jobid}.${SGE_TASK_ID:-jobindex}''');
r = strrep(r, 'jobid', '');
r = strrep(r, '.jobindex', '');
id = strtrim(r);
if isempty(id)
    id = '';
end
