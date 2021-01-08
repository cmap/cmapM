classdef Regression
% Algorithms for regression analysis

    methods(Static=true)

       %==Multiple linear regression methods
       model = trainMLR(varargin);
       ds = testMLR(varargin);             
    end % Static methods block
       
end
