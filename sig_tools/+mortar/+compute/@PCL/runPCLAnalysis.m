function out = runPCLAnalysis(varargin)

    [args, help_flag] = get_args(varargin{:});

    if ~help_flag
        % load data
        [ds, pcl, pcl_info] = mortar.compute.PCL.getData(args);
    
        % compute PCL scores
        rpt = mortar.compute.PCL.computePCLScores(ds, pcl, pcl_info);
    
        out = struct('args', args,...
                 'ds', ds,...
                 'pcl', pcl,...
                 'pcl_info', pcl_info,...
                 'rpt', rpt);
    end
end

function [args, help_flag] = get_args(varargin)
    ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));

    opt = struct('prog', mfilename, 'desc', 'Compute PCL scores', 'undef_action', 'ignore');
    
    [args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});
end
