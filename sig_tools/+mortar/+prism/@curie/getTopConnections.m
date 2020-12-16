function getTopConnections(varargin)

[args, help_flag] = getArgs(varargin{:});
if ~help_flag

else
    
end

end

function [args, help_flag] = getArgs(varargin)% inputs dataset
% theshold format: 
% score_cutoff: scalar, "low,high"
% percentile_cutoff: scalar, "low,high"
% custom_picks: binary matrix indicating picks
% row_rank_cutoff: scalar, "low,high"
% col_rank_cutoff: scalar, "low,high"

config = struct('name', {'--ds';'--score_threshold';'--prefix';'--suffix'},...
    'default', {[];true;'';''},...
    'help', {'Number of widgets'; 'Apply zeropading';
    'Add a prefix'; 'Add a suffix'});
opt = struct('prog', 'widgetizer', 'desc', 'Build widgets');
input = {10, '--prefix', 'Mc' '--zeropad', false};
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, input{:});

end