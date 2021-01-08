classdef Calib
    % Calib: Apply various analyses to a build of a pilot calibration plate
    % to gain insight on optimizing parameters for future experiments.
    % Utilizes information from a build, including GUTC and siginfo files
    % to produce and save relevant figures.
    
    methods(Static)
        %Ensure parameters are field in siginfo table and print unique values
        %for each parameter
        exp_params = validate_parameters(siginfo_table, list, prt);
        
        %Choose and prepare plots for specified parameters.
        output = build_calib_plots(varargin);
        
        %plot TAS
        plot_TAS_from_siginfo(varargin);
        
        %make GUTC membership heatmap
        mk_gutc_heatmap(varargin);
        
    end
    
end
