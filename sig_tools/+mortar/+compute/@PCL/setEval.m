function rpt = setEval(varargin)
if nargin<1
    warning('No arguments supplied')
    varargin={'-h'};
end
import mortar.util.Message
[args, help_flag] = getArgs(varargin{:});

rpt = [];
if ~help_flag
    % Split input dataset
    % Evaluate set on each subset
    % Assess statistical significance
end

end

function [args, help_flag] = getArgs(varargin)
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});
end