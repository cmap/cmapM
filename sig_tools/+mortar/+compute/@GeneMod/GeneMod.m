classdef GeneMod
% Algorithms to identify gene modulators

    methods(Static=true)

        % Gene mod core algorithms
        % Aggregate zscores
        aggzs = aggregateZScore(zs, gp_var);
        % 
        %res = getGeneModMatrix(aggzs, rid, topn);    
        gmres = getGeneModByCell(aggzs);
        topres = getTopMod(gmres, n);
        res = getMaxqMod(gmres);
        
        plotModMap(x, title_str, name_str, showfig);
        
        % helper script
        res = runGeneMod(varargin);
        
    end % Static methods block
       
end
