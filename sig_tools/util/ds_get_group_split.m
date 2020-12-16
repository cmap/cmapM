function ds_groups = ds_get_group_split(ds, group_by, split_by, varargin)
% DS_GROUP_SPLIT Group and split a dataset based on metadata
% DS_GROUP_SPLIT(DS, GB, SB)
% dim
% col_meta
% row_meta

[args, help_flag] = parseArgs(varargin{:});

end

function [args, help_flag] = parseArgs(varargin)
pname = {'ds', '--group_by', '--split_by'};
dflts = {[], '', ''};
help_str = {'', '', ''};
config = struct('name', pname,...
                  'default', dflts,...
                  'help', {'Number of widgets'; 'Apply zeropading';
                  'Add a prefix'; 'Add a suffix'});
  opt = struct('prog', 'widgetizer', 'desc', 'Build widgets') 
  input = {10, '--prefix', 'Mc' '--zeropad', false};
  [args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, input{:});

end