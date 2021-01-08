classdef GEO
    % Methods for processing gene expression data from GEO
    methods(Static=true)
        % Convert CXT files to GEX matrix
        [gex, missing] = cxt2gex(cxtlist, varargin);
        % Normalize raw gene expression data
        [qn,sc] =  gex2norm(varargin);
    end
end