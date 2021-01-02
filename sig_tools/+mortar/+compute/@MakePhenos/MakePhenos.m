classdef MakePhenos
    % MakePhenos: Generate phenotypes file for use in SigMarker tool. 
    % Splits instinfo file into classes for comparison of treatment to
    % control
    
    methods(Static)
        ops_table = generate_ops_table(table, params);
        
        [outtable, siginfotable, failed_list] = make_phenotypes(instinfo, varargin); 
    end
    
end
