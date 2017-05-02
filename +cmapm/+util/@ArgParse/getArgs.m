function [args, help_flag] = getArgs(config, opt, varargin)
% args = getArgs(config, opt, varargin) Parses command-line arguments
% specified in config and returns a structure with fieldnames
% corresponding to each argument. Config can be a YAML formatted file or
% any valid input to @ArgParse/add. Opt is structure with the following
% fields:
% 'prog' String, Program name, Required
% 'desc' String, Description of the program, Optional. Default is ''
% 'undef_action' String, Action to take if an undefined argument is
%                encountered. Default is 'warn'. Choices are {'ignore',
%                'warn', 'error'}
%
% Examples:
% config = struct('name', {'n';'--zeropad';'--prefix';'--suffix'},...
%                 'default', {[];true;'';''},...
%                 'help', {'Number of widgets'; 'Apply zeropading';
%                 'Add a prefix'; 'Add a suffix'});
% opt = struct('prog', 'widgetizer', 'desc', 'Build widgets') 
% input = {10, '--prefix', 'Mc' '--zeropad', false};
% args = cmapm.common.ArgParse.getArgs(config, opt, input{:});

%% TODO Add YAML example

% assert(cmapm.common.FileUtil.isfile(config, 'file'),...
%     'File not found: %s', config);

valid_opt = struct('prog', '', 'desc', '', 'undef_action', 'warn');
cmn_field = intersect(fieldnames(valid_opt), fieldnames(opt));
for ii=1:length(cmn_field)
    valid_opt.(cmn_field{ii}) = opt.(cmn_field{ii});
end
%assert(~isempty(valid_opt.prog), 'The prog field in opt cannot be empty');
parser = cmapm.util.ArgParse(valid_opt.prog, valid_opt.desc);
parser.undef_action = valid_opt.undef_action;
if cmapm.util.File.isfile(config, 'file')
    parser.addFile(config);
else
    try
        parser.add(config);
    catch e        
        rethrow(e);
    end
end

args = {};
help_flag = false;
try
    args = parser.parse(varargin{:});
catch ME
    if strcmp(ME.identifier, 'cmapm:common:ArgParse:HelpRequest')
        help_flag = true;
    else
        error('%s %s', ME.identifier, ME.message);
    end
end

end
