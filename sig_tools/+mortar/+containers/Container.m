classdef Container < handle
    %Base class for all containers.
    
    properties
        %size

    end
    
    properties (Access=protected)
        data_
    end
    
    methods(Abstract=true)
        % Dimensions
        d = size(obj)
        
        % Length of largest dimension of container
        n = length(obj)
        
        % Test if container is empty
        tf = isempty(obj)
        
        % 
        parse(obj, src)
        
        % display the contents of an object
        disp(obj)
        
        % save an object to specified target
        save(obj, tgt)
    end
    
end

