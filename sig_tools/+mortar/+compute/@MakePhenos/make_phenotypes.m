function [outtable, sig_params_tbl, failed_list] = make_phenotypes(instinfo, varargin)
% Generate phenotypes file from provided

    pnames = {'ctl_params', ...
        'trt_params', ...
        'ctl_id_pair', ...
        'param_fields', ...
        'class_label_field', ...
        'ignore_missing', ...
        'prefix'};
    dflts = {{'cell_id'},...
            {'pert_iname'}, ...
            {'pert_iname', 'DMSO'}, ...
            {'pert_iname', 'cell_id', 'pert_itime', 'pert_idose'}, ...
            'pert_iname', ...
            false,...
            ''};

    % make a separate parameter for grouping control
        
    args = parse_args(pnames, dflts, varargin{:});
   
    if ~iscell(args.ctl_params)
        ctl_params = {args.ctl_params};
    else
        ctl_params = args.ctl_params;
    end
    
    if ~iscell(args.trt_params)
        trt_params = {args.trt_params};
    else
        trt_params = args.trt_params;
    end   

    param_fields = args.param_fields;
    param_fields = union(param_fields, trt_params);
    param_fields = union(param_fields, ctl_params); 

    if ~isstruct(instinfo)
        instinfo = parse_record(instinfo);
    end    
    
    assert(numel(args.ctl_id_pair) == 2, '--ctl_id_pair of length two: field, value');
    ctl_id_field = args.ctl_id_pair{1};
    ctl_id_val = args.ctl_id_pair{2};
    control_label = ctl_id_val;
    
    assert(ismember(ctl_id_field, fieldnames(instinfo)), '--ctl_id_pair field not found in instinfo');

    missing_field = setdiff(param_fields, fieldnames(instinfo));
    for i=1:numel(missing_field)
        fprintf('Instinfo file missing field: %s \n', missing_field{i});
    end
    
    param_fields = intersect(fieldnames(instinfo), param_fields);
    
    %generate all possible combinations
    pretable = mortar.compute.MakePhenos.generate_ops_table(instinfo, ctl_params);
   
    outtable = struct('sample_id', [], 'class_id', [], 'class_label', [], 'sig_id', []); %Prep output struct

    nfields = numel(param_fields);
    sig_fields = cell(1, 2*numel(param_fields) + 1);
    sig_fields(1,1) = {'sig_id'};
    sig_fields(1, 2:nfields+1) = param_fields;
    sig_fields(1, nfields+2:2*nfields+1) = strcat(param_fields, '_ctl');
    

    sig_params = cell(1,nfields*2+1);

    ctl_param_table = cell2table(pretable, 'VariableNames', ctl_params);
    [r,c] = size(ctl_param_table);

    failed_list = cell(1,c);
    out_idx = 1;
    sig_idx = 1;
    failed_idx = 1;
    for ii=1:r %for each combination
        sub_table = instinfo;
        ctl_param_str = ctl_id_val;
        for jj=1:c %subset down to current control experimental parameters
            if iscellstr(ctl_param_table.(ctl_params{jj})(ii))
                sub_table = sub_table( strcmp({sub_table.(ctl_params{jj})}, ctl_param_table.(ctl_params{jj})(ii) ), :);
            else
                sub_table = sub_table( [sub_table.(ctl_params{jj})] == ctl_param_table.(ctl_params{jj})(ii), :);
            end
            if isnumeric([ctl_param_table.(ctl_params{jj})])
                param_str = num2str(ctl_param_table.(ctl_params{jj})(ii));
            else
                param_str = regexprep(ctl_param_table.(ctl_params{jj}){ii}, ' ', '');
            end
            ctl_param_str = [ctl_param_str '_' param_str];
        end 

        %We have table subsetted by control parameters
        ctl_table = sub_table(strcmp({sub_table.(ctl_id_field)}, ctl_id_val));
        trt_table = sub_table(~strcmp({sub_table.(ctl_id_field)}, ctl_id_val));

        %Need to subset further by trt_parameters
        %trt_params = setdiff(trt_params, ctl_params);
        if (args.ignore_missing)
            if isempty(ctl_table)
                fprintf('No controls to compare to for following conditions:\n');
                print_dlm_line(ctl_param_table{ii,:}, 'dlm', ', ')
                fprintf('Check instinfo file and parameters\n');
                failed_list(failed_idx, :) = ctl_param_table{ii,:};
                failed_idx = failed_idx + 1;
                continue
            end
            if isempty(trt_table)
                fprintf('No treaments to compare to control, for following conditions:\n');
                print_dlm_line(ctl_param_table{ii,:}, 'dlm', ', ')
                fprintf(['Check instinfo file and treatment parameters\n'...
                    'pert_iname can not be a ctl_param']);
                failed_list(failed_idx, :) = ctl_param_table{ii,:};
                failed_idx = failed_idx + 1;
                continue
            end
        else
            assert(~isempty(ctl_table), ...
                ['No controls to compare to, check parameters. ' ...
                'To skip enable --ignore_missing flag'])
            assert(~isempty(trt_table), ...
                ['No treatments to compare to control ' ...
                'To skip enable --ignore_missing flag'])
            assert(~isempty(trt_params), ...
                ['Treatment and control parameters are identical '...
                'To skip enable --ignore_missing flag'])
        end
        
        trt_pretable = mortar.compute.MakePhenos.generate_ops_table(trt_table, trt_params);

        trt_param_table = cell2table(trt_pretable, 'VariableNames', trt_params);
        [t_r, t_c] = size(trt_param_table);    

        for kk=1:t_r
            trt_sub_table = trt_table;
            sig_id_str = ''; 
            for ll=1:t_c
                if iscellstr(trt_param_table.(trt_params{ll})(kk))
                    trt_sub_table = trt_sub_table( strcmp({trt_sub_table.(trt_params{ll})}, trt_param_table.(trt_params{ll})(kk) ), :);
                else
                    trt_sub_table = trt_sub_table( [trt_sub_table.(trt_params{ll})] == trt_param_table.(trt_params{ll})(kk), :);
                end
                if isnumeric([trt_param_table.(trt_params{ll})])
                    param_str = num2str(trt_param_table.(trt_params{ll})(kk));
                else
                    param_str = regexprep(trt_param_table.(trt_params{ll}){kk}, ' ', '');
                end
                sig_id_str = [sig_id_str '_' param_str];    
                %siginfo(sig_idx, t_c) = trt_param_table.(trt_params{ll})(kk);
            end

            if (numel(trt_sub_table) < 1)
                continue
            end
            
            % Generate sig_ids
            trt_class = unique({trt_sub_table.(ctl_id_field)});
            assert(numel(trt_class) < 2)
            if ~isempty(args.prefix)
                prefix = regexprep(args.prefix, '_$', '');  
                sig_id_str = regexprep(sig_id_str, '^_', '');
                sig_id = upper(sprintf('%s_%s_vs_%s', prefix, sig_id_str, ctl_param_str));
            else
                sig_id = upper(sprintf('%s_vs_%s', regexprep(sig_id_str, '^_', '') , ctl_param_str));
            end
            
            %Generate phenotypes table
            for ll=1:numel(trt_sub_table)
                sample_id = sprintf('%s:%s', trt_sub_table(ll).det_plate, trt_sub_table(ll).det_well);
                outtable(out_idx) = struct('sample_id', sample_id, 'class_id', 'A', 'class_label', trt_class, 'sig_id', sig_id);
                out_idx = out_idx + 1;
            end

            for ll=1:numel(ctl_table)
                sample_id = sprintf('%s:%s', ctl_table(ll).det_plate, ctl_table(ll).det_well);
                outtable(out_idx) = struct('sample_id', sample_id, 'class_id', 'B', 'class_label', control_label, 'sig_id', sig_id);
                out_idx = out_idx + 1;
            end

            %Generate sig_params table

             
             sig_params(sig_idx, 1) = {sig_id};
             for ll = 1:nfields
                   if iscellstr({trt_sub_table.(param_fields{ll})})
                       sig_params{sig_idx, ll+1} = strjoin(unique({trt_sub_table.(param_fields{ll})}));
                   else
                       cell_vals = cellfun(@num2str,num2cell(unique([trt_sub_table.(param_fields{ll})])),'un',0);
                       sig_params{sig_idx, ll+1} = strjoin(cell_vals, '|');
                   end
                   if iscellstr({ctl_table.(param_fields{ll})})
                       sig_params{sig_idx, nfields+ll+1} = strjoin(unique({ctl_table.(param_fields{ll})}));
                   else
                       cell_vals = cellfun(@num2str,num2cell(unique([ctl_table.(param_fields{ll})])),'un',0);
                       sig_params{sig_idx, nfields+ll+1} = strjoin(cell_vals, '|');
                   end
             end
             
%             for ll = 1:t_c
%                 if isnumeric(trt_param_table.(trt_params{ll})(kk))
%                     sig_params(sig_idx, ll+1) = num2cell(trt_param_table.(trt_params{ll})(kk)); 
%                 else
%                     sig_params(sig_idx, ll+1) = trt_param_table.(trt_params{ll})(kk); 
%                 end
%             end
%             for ll=1:nctl
%                 sig_params(sig_idx, t_c +ll+1) = ctl_param_table.(ctl_params{ll})(ii);
%             end
             sig_idx = sig_idx + 1;
        end
    end

    outtable = struct2table(outtable);
    sig_params_tbl = cell2table(sig_params, 'VariableNames',sig_fields);
    failed_list = cell2table(failed_list, 'VariableNames', ctl_params);
    
end

