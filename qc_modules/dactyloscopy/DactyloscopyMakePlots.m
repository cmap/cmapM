classdef DactyloscopyMakePlots
    properties
        result_dir
    end

    methods
        %constructor
        function obj = DactyloscopyMakePlots(dactyloscopy_result_dir)
            % constructor used to create the DactyloscopyMakePlots object
            % Input:
            %   dactyloscopy_result_dir - a directory with the results from
            %           dactyloscopy_single
            obj.result_dir = dactyloscopy_result_dir;
        end

        function make_plots(obj, varargin)
            %% make_plots(obj, varargin)
            %
            % Function (class method) to generate figures with a heatmap of ranks and correlation
            % coefficient plots from the results of dactyloscopy_single.
            % 
            % Input:
            %   save_out - a logical variable if any output file should be saved
            %           (default value is set to: true)
            %   dname_out - a directory name where all the output files will be saved
            %           (default value is set to the directory specified with the 
            %           obj.result_dir option)
            %
            % Output:
            %   rank_heatmap.png - heatmap with the rank of the cell line on the plate
            %   cc.png - correlation coefficient for the 10 cell lines with the highest
            %           rank (including the cell line on the plate)
            % Example:
            %   my_dmp = DactyloscopyMakePlots('/dactyloscopy_LJP006_PC3_24H_X3_B19')
            %   my_dmp.make_plots()
            %
            % E-mail: Marek Orzechowski morzech@broadinstitute.org

            %% ArgsParse
            pnames = {'--save_out', '--dname_out'};
            dflts = {true, obj.result_dir};
            config = struct('name',pnames, 'default',dflts, 'help', ...
                    {'Save output files', 'Directory with the output files'});
            opt = struct('prog', mfilename, 'desc',...
                'Make plots from dactyloscopy_single results', 'undef_action','error');

            args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
            disp(args)

            %% Assert that all the necessary files exist and all the options are set properly
            if ischar(obj.result_dir)
                if exist(fullfile(obj.result_dir,'dactyloscopy_test.txt'),'file')==0
                    error('%s> A txt file with the results of dactyloscopy_single analysis: %s could not be found.',...
                        mfilename, fullfile(obj.result_dir,'dactyloscopy_test.txt'))
                end
            else
                error('%s> Value of the result_dir for the object (obj.result_dir) should be a string',mfilename)
            end

            save_out=args.save_out;
            if ~islogical(save_out)
                error('%s> Value of save_out needs to be of logical type', mfilename)
            end

            if save_out
                dname_out=args.dname_out;
                if exist(dname_out,'dir')==0
                    mkdir(dname_out)
                    warning('%s> Output directory: %s could not be found and was just created.',...
                        mfilename, dname_out)
                end
            end

            %%
            dtt = readtable(fullfile(obj.result_dir,'dactyloscopy_test.txt'),...
                'Delimiter','\t');
            %dt = obj.table2struct(dtt);
            dt = table2struct(dtt);

            fprintf('Working on the dactyloscopy_single output table:\n')
            disp(dtt)

            % Conversion num2char is needed to add informtation about the rank to the
            % title
            if isnumeric(dtt.rank)
                title_rank = stringify(dtt.rank);
            else
                title_rank = dtt.rank;
            end

            if isnumeric(dtt.rank_lincs)
                title_rank_lincs = stringify(dtt.rank_lincs);
            else
                title_rank_lincs = dtt.rank_lincs;
            end
            
            if ~iscell(title_rank)
                title_rank = {title_rank};
            end
            
            if ~iscell(title_rank_lincs)
                title_rank_lincs = {title_rank_lincs};
            end
            % Conversion is finished, title_rank and title_rank_lincs will be used

            %% Plot figures for each unique cell line
            for ii = 1:length(dt)
                fprintf('%s> Working on: %s and cell line: %s\n\n',...
                mfilename, dt(ii).det_plate, dt(ii).cell_id_annot)
                if ~strcmp(dt(ii).rank,'missing')
                    cell_id_annot = dt(ii).cell_id_annot;
                    cell_id = dt(ii).cell_id;

                    dr_file = obj.find_report_file('ds_rank_', cell_id_annot);
                    dr = parse_gctx(dr_file);

                    % Plot heatmap with ranks
                    if dt(ii).is_guessed==1
                        rank_idx = ismember(dr.rid,cell_id);
                    else
                        rank_idx = ismember(dr.rid,cell_id_annot);
                    end

                    cm = distinguishable_colors(11);
                    rank_cell_line = dr.mat(rank_idx,:);
                    rank_above_10_idx = rank_cell_line>10;
                    rank_cell_line(rank_above_10_idx) = 11;
                    hm = plot_platemap(rank_cell_line,ds_get_meta(dr,'column','rna_well'),...
                        'caxis', [1 12]);
                        colormap(cm);
                        cb = colorbar;
                        set(cb,'Ticks',[1:11]+0.5)
                        set(cb,'TickLabels',stringify([1:11]'))
                    
                        title(sprintf('%s, cell_id_annot: %s, cell_id: %s\n rank: %s, rank_lincs: %s',...
                        dt(ii).det_plate, dt(ii).cell_id_annot, ...
                        dt(ii).cell_id, title_rank{ii}, title_rank_lincs{ii}), ...
                        'interpreter','none','FontSize', 13)

                    % Plot correlation coefficient
                    dcc_file = obj.find_report_file('ds_cc_', cell_id_annot);
                    dcc = parse_gct(dcc_file);
                    
                    cc_idx = find(ismember(dcc.rid,cell_id)==1);
                    [~,b] = get_wellinfo(ds_get_meta(dcc,'column','rna_well'));
                    
                    pcc = figure;
                    % Creata an array with well index in the first column and top
                    % 10 cell lines (including the one on the plate) in the
                    % columns from 2 to 11. Sort this array by the well index
                    if cc_idx>10
                        dcc_to_plot = ds_slice(dcc,'rid',dcc.rid([cc_idx,1:9]));
                        dplot = sortrows([b,dcc_to_plot.mat'],1);
                    else
                        dcc_to_plot = ds_slice(dcc,'ridx',[cc_idx,setdiff(1:10,cc_idx)]);
                        dplot = sortrows([b,dcc_to_plot.mat'],1);
                    end
                    % Plot correlation coefficients
                    plot(dplot(:,1),dplot(:,2), '-', 'LineWidth', 3)
                    hold on
                    plot(dplot(:,1),dplot(:,3:11), '-', 'LineWidth', 2)
                    hold off
                    
                    legend(dcc_to_plot.rid,...
                    'Location','southeast','FontSize',8)
                    
                    l = flip(findobj(pcc,'type','line'));
                    for jj= 1:length(l)
                        l(jj).Color = cm(jj,:);
                    end
                    
                    xmin = min(dplot(:,1))-1;
                    xmax = max(dplot(:,1))+1;
                    ymin = min(min(dplot(:,2:end)))-0.2;
                    ymax = max(max(dplot(:,2:end)))+0.1;
                    xlim([xmin xmax])
                    ylim([ymin ymax])
                    xlabel('Well index')
                    ylabel('Spearman CC')
                    title(sprintf('%s, cell_id_annot: %s, cell_id: %s\n rank: %s, rank_lincs: %s',...
                    dt(ii).det_plate, dt(ii).cell_id_annot, ...
                    dt(ii).cell_id, title_rank{ii}, title_rank_lincs{ii}), ...
                    'interpreter','none','FontSize', 13)

                    if save_out
                        saveas(hm,fullfile(dname_out,strcat('rank_heatmap_',cell_id_annot,'.png')),'png')
                        saveas(pcc,fullfile(dname_out,strcat('cc_',cell_id_annot,'.png')),'png')
                        % Closing only figures created in the most recent instance
                        % of this function
                        figures = findall(0,'type','figure');
                        close(figures(1:2))
                    end
                else
                    fprintf('%s> Cell line: %s was not found in the reference library\n',...
                        mfilename, dt(ii).cell_id_annot)
                    fprintf('%s> No plots will be generated\n\n',mfilename)
                end
            end
        end

        function dr_file = find_report_file(obj, report_file_prefix, cell_id_annot)
            drf_search = strcat(report_file_prefix, cell_id_annot, '_n*.gct');
            drf_search_path = fullfile(obj.result_dir, drf_search);
            drf = dir(drf_search_path);

            did_fail = false;
            if ~isempty(drf)
                dr_file = fullfile(obj.result_dir, drf.name);

                did_fail = ~exist(dr_file);
            else
                did_fail = true;
            end

            if did_fail
                warning('%s> GCT file with ranks for cell line %s was not found', mfilename, cell_id_annot)
                dr_file = [];
            end
        end

%         function s = table2struct(obj, t, varargin)
%             %TABLE2STRUCT Convert table to structure array.
%             %   S = TABLE2STRUCT(T) converts the table T to a structure array S.  Each
%             %   variable of T becomes a field in S.  If T is an M-by-N table, then S is
%             %   M-by-1 and has N fields.
%             %
%             %   S = TABLE2STRUCT(T,'ToScalar',true) converts the table T to a scalar
%             %   structure S.  Each variable of T becomes a field in S.  If T is an
%             %   M-by-N table, then S has N fields, each of which has M rows.
%             %
%             %   S = TABLE2STRUCT(T,'ToScalar',false) is identical to S = TABLE2STRUCT(T).
%             %
%             %   See also STRUCT2TABLE, TABLE2CELL, TABLE.
% 
%             %   Copyright 2012-2013 The MathWorks, Inc.
% 
%             % Marek Orzechowski (06/23/2016):
%             % This is a Matlab function and it was copied and pasted here to resolve
%             % a conflict with another function in the espresso dir with the same name but
%             % different syntax
% 
%             v = version;
%             
%             import matlab.internal.tableUtils.validateLogical
% 
%             pnames = {'ToScalar'};
%             dflts =  {    false };
%             [toScalar] = matlab.internal.table.parseArgs(pnames, dflts, varargin{:});
% 
%             toScalar = validateLogical(toScalar,'ToScalar');
%             if toScalar
%                 s = cell2struct(getData(t),t.Properties.VariableNames,2);
%             else
%                 s = cell2struct(table2cell(t),t.Properties.VariableNames,2);
%             end
%         end
    end
end
