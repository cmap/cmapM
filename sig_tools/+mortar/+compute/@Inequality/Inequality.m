classdef Inequality
    % Measures of Inequality
    
    methods(Static=true)        
        % Gini Coefficient        
        % Port of R acid unweighted.gini method
        % Supports weights, bias correction and handles missing values
        % This is the recommended implementation
        [G, bcG, bcwG] = weightedGini(x, varargin);
        
        % Alternate implementations
        % StatsNZ's weighted-Gini implementation
        % should match weightedGini, but is slower and does not compute
        % bias corrected estimates
        G = statsNZGini(x, varargin);
        
        % Port of R ineq method
        % supports unweighted Gini and Atkinson
        m = ineq(x, varargin);
        
    end
end