function out = runQuery(varargin)
% runQuery : 

[args, help_flag] = get_args(varargin{:});

import mortar.util.Message

if ~help_flag  
    out = struct('args', args,...
             'cs', '',...
             'ns', '',...
             'ps', '',...
             'query_stats', '');
         
    %% PDEX filepaths
    pdex_rpt = mortar.compute.Pdex.getDataFiles(args.pdex_path);
    if ~isempty(args.query_result_folder)
        Message.log(args.verbose, '# Reading pre-computed query');
        query_result = mortar.compute.Pdex.loadQueryResult(args.query_result_folder, true);        
        out.query_stats = query_result.query_stats;
    else
        Message.log(args.verbose, '# Running query against PDEX dataset');
        query_result = mortar.compute.Connectivity.runCmapQuery(...
            'score', pdex_rpt.build_score, ...
            'rank', pdex_rpt.build_rank, ...
            'uptag', args.up,...
            'es_tail', 'up',...
            'metric', 'wtcs');        
        % annotate query result
        query_result.cs = annotate_ds(query_result.cs, pdex_rpt.annot_col, 'dim', 'row');
        query_stats = struct('query_id', {query_result.uptag.head}',...
               'query_desc', {query_result.uptag.desc}',...
               'up_size', num2cell([query_result.uptag.len]'));            
        out.query_stats = query_stats;
    end
    out.cs = query_result.cs;
    query_size = [out.query_stats.up_size]';

    %% Normalize scores
    [ncs, rpt, posmu, negmu] = mortar.compute.Gutc.normalizeQueryRef(out.cs, query_result.cs.rid);

    %% Compute percentiles
    Message.log(args.verbose, '# Computing percentiles stratified by query size');
    [out.ps, out.ns] = mortar.compute.Gutc.scoreToPercentileBySize(ncs,...
                        pdex_rpt.ns2ps_lookup, 'column', query_size);
end
end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Compute PDEX queries and GUTC', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

end


