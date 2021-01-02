function [status, result] = r_cmd(varargin)
% R_CMD Execute a R script from Matlab
% [S, R] = R_CMD(SCRIPT, ARG1, ARG2,...) Executes SCRIPT with the provided
% arguments. Returns the exit code S and the stdout /stderr response as a
% string R.
%
% The function uses a simple BASH wrapper that supports host-specific
% configurations.
%
% In order to determine the wrapper script to use, it first checks for the
% MORTAR_R_WRAPPER environment variable. If the variable is empty it
% searches for a host-specific wrapper scripts in:
% fullfile(mortarpath, 'ext', 'bin', <hostname>_r_wrapper.sh)
% Failing which it uses broad_r_wrapper.sh on Broad servers that support
% custom CMAP dotkits. On non-Broad hosts it defaults to
% generic_r_wrapper.sh
%
% You can specify your own configuration in two ways:
% 1. Create / Modify an existing bash wrapper and save it in:
% fullfile(mortarpath, 'ext', 'bin', <hostname>_r_wrapper.sh)
% 2. Specify the MORTAR_R_WRAPPER environment variable

if nargin
    % use wrapper script specified in the environment
    wrapper_envar = 'MORTAR_R_WRAPPER';
    wrapper = getenv(wrapper_envar);
    if isempty(wrapper)
        % check if hostname specific wrapper exists
        host_wrapper_file = fullfile(mortarpath, 'ext', 'bin', ...
            sprintf('%s_r_wrapper.sh', hostname));
        if mortar.util.File.isfile(host_wrapper_file)
            wrapper = host_wrapper_file;
        else        
        % default to the generic wrapper
        wrapper = fullfile(mortarpath, 'ext', 'bin', ...
            'generic_r_wrapper.sh');
        % if on a Broad host, switch to Broad specific wrapper 
        if isunix && ~ismac
            [st, res] = system('hostname -d');
            if isequal(st, 0)
                domain = deblank(res);
                if (strcmp(domain, 'broadinstitute.org'))
                    wrapper = fullfile(mortarpath, 'ext', 'bin', ...
                        'broad_r_wrapper.sh');
                end
            end
        end
        end
    end
    if ~isempty(wrapper)
        assert(mortar.util.File.isfile(wrapper, 'file'),...
            'Wrapper file not found: %s', wrapper);
        dbg(1, 'Using wrapper: %s', wrapper);
        [status, result] = exec_r_cmd(wrapper, varargin{:});
    else
        error('R wrapper not found for host. Set the %s environment variable to specify a custom wrapper', wrapper_envar);
    end
else
    status = 1;
    result = 'No arguments provided';
end

end

function argstr = get_argstr(varargin)
argstr = print_dlm_line(singlequote(varargin), 'dlm', ' ');
end

function [status, result] = exec_r_cmd(wrapper, varargin)
argstr = get_argstr(varargin{:});
cmdstr = sprintf('bash %s %s', wrapper, argstr);
[status, result] = system(cmdstr);
end
