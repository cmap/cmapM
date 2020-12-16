function out = runMatchedGutc(varargin)
% Run matched-mode GUT-C

import mortar.compute.Gutc;

[args, help_flag] = get_args(varargin{:});

import mortar.util.Message

if ~help_flag    
    t0 = tic;
    
    out.args = args;
    
    Message.debug(args.verbose, 'Computing matched results....');

    % parse dataset
    ds = parse_gctx(args.ds); 
    if ~isempty(args.row_meta)
        ds = annotate_ds(ds, args.row_meta, 'dim', 'row', 'keyfield', 'id');
    end    
    if ~isempty(args.column_meta)
        ds = annotate_ds(ds, args.column_meta, 'dim', 'column', 'keyfield', 'sig_id');
    end

    %% Match queries to rows to obtain pert matrix
    Message.debug(args.verbose,...
                   '# Matching queries to rows by %s for each %s',...
                   args.match_field, args.id_field);
    out.tpc = mortar.compute.Gutc.matchQuery(ds, 1, args.match_field, args.id_field);
    out.tpc = mortar.compute.Gutc.castDSToLong(out.tpc, 'cell_id', {'pert_id', 'pert_itime','pert_idose'});
    
%% summly space if requested
%     if args.use_summly_space        
%          summly_sig = mortar.common.Spaces.sig('summly_ts').asCell;
%          [~, ridx]=intersect_ord(out.ts.rid, summly_sig);
%          [~, tpc_rid] = get_groupvar(out.ts.rdesc(ridx,:),...
%                                      out.ts.rhd,...
%                                      {'pert_id','cell_id'});
%     else
%         tpc_rid = {};
%     end                                                             


    %% Aggregate TPC rows by pert_id
    Message.debug(args.verbose, '# Aggregating pert_cell rows by pert_id');
    out.tp = Gutc.aggregateQuery(out.tpc, '',...
                                {'pert_id'}, 1,...
                                args.aggregate_method, args.aggregate_param);
    % drop cell id
    out.tp = ds_delete_meta(out.tp, 'row', 'cell_id');

%% Aggregate TP rows by pert_iname
    Message.debug(args.verbose, '# Aggregating pert rows by pert_iname');
    out.tn = Gutc.aggregateQuery(out.tp, '',...
                                 {'pert_iname', 'pert_type'}, 1,...
                                 args.aggregate_method, args.aggregate_param);
        
    Message.debug(args.verbose, 'Done in %2.1f s', toc(t0));            
            
end
end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Compute GUTC in matched mode', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

% parser = mortar.common.ArgParse(mfilename);
% parser.undef_action = 'ignore';
% out_path = fileparts(mfilename('fullpath'));
% parser.addFile(fullfile(out_path, [mfilename, '.arg']));
% 
% try
%     args = parser.parse(varargin{:});
% catch ME
%     if strcmp(ME.identifier, 'mortar:common:ArgParse:HelpRequest')
%         rethrow(ME);
%     else
%         error('%s %s', ME.identifier, ME.message);
%     end
% end

% sanity checks

% assert((isequal(args.es_tail, 'both') && ~isempty(args.uptag) && ~isempty(args.dntag)) ||...
%         (isequal(args.es_tail, 'up') && ~isempty(args.uptag)) ||...
%         (isequal(args.es_tail, 'down') && ~isempty(args.dntag)),...
%         'Invalid query specified');

end
