classdef Pdex
% Algorithms to compute connectivity between patient sample sets 
% and CMap pertubations.

    methods(Static=true)      

        % Process raw connectivity scores using unmatched-mode GUTC
        opt = runQuery(varargin);
        rpt = getDataFiles(pdex_path);
        
        query_result = loadQueryResult(qres_folder, parse_files);
        saveQueryResult(res, out_path, use_gctx);
                        
    end % Static methods block
       
end
