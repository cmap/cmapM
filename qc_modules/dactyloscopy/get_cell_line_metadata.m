function sfds = get_cell_line_metadata(cell_id_annot, ds_ref, ...
        ds_plate_slice, lincs_lines, api_user_key, dp_cline_dict, use_dp_cline_dict)
%% Some description
%
% E-mail: Marek Orzechowski morzech@broadinstitute.org

fprintf('%s> Getting metadata for a cell line: %s\n',mfilename,cell_id_annot{1})

% Some cell_ids contain only digits and for ismember to work those must
% be converted to strings
if isnumeric(cell_id_annot)
    cell_id_annot = {num2str(cell_id_annot)};
end

% There are cases where the cell_id says -666 (for whatever reason)
if logical(ismember(cell_id_annot, '-666'))
    cell_id = cell_id_annot;
    cell_line_is_missing = true;
    cell_line_is_guessed = false;
    cell_line_is_lincs = false;
    cell_line_is_member = false;
    cell_lineage = '-666';
    cell_histology = '-666';
    warning('%s> Unknown cell line: %s',mfilename, cell_id_annot{1})
else
    % Query API to check if tested cell line is derivatized. If so, its
    % cell_id is extracted from the query result.
    q_cell_id = cell_query_api('--user_key',api_user_key,'--where',...
        strcat('"derived_cell_lines":"',cell_id_annot{1},'"'));
    
    if ~isempty(q_cell_id)
        cell_id_tmp = {cell_id_annot, q_cell_id.cell_id};
    else
        if use_dp_cline_dict
            is_in_dict = ismember(dp_cline_dict.cell_id_derived_line, cell_id_annot);
            if sum(is_in_dict)==1
                cell_id_tmp = [cell_id_annot, dp_cline_dict.cell_id(is_in_dict)];
                fprintf('%s> Result of a cell line dictionary search shows that\n',mfilename)
                fprintf('%s> cell_id_annot: %s corresponds to: %s\n',...
                    mfilename,cell_id_tmp{1},cell_id_tmp{2})
            else
                fprintf('%s> Result of a cell line dictionary search was empty\n',mfilename)
                cell_id_tmp = guess_cell_line(cell_id_annot, ds_ref.cid);    
            end
        else 
            fprintf('%s> Result of an API query was empty\n',mfilename)
            cell_id_tmp = guess_cell_line(cell_id_annot, ds_ref.cid);
        end
    end
    
    % If guessing failed, appropriate message is printed
    if isempty(cell_id_tmp)
        cell_id = cell_id_annot{1};
        cell_line_is_missing = true;
        cell_line_is_guessed = false;
        cell_line_is_lincs = false;
        cell_line_is_member = false;
        cell_lineage = '-666';
        cell_histology = '-666';
        fprintf('%s> Cell line %s does not match any cell line profile ',...
            mfilename, cell_id)
        fprintf('in the reference list of cell lines. \n')
    else
        cell_id = num2str(cell_id_tmp{2});
        fprintf('%s> Detected cell line: %s\n',mfilename,cell_id)
        % If a cell line is part of the list of reference cell lines
        % everything is fine.
        if logical(ismember(cell_id, ds_ref.cid))
            cell_line_is_missing = false;
            cell_line_is_member = true;
        else
            cell_line_is_missing = true;
            cell_line_is_member = false;
        end
        
        if strcmp(cell_id_tmp{1},cell_id_tmp{2})
            cell_line_is_guessed = false;
        else
            cell_line_is_guessed = true;
        end
        % Check if a cell line is part of lincs
        if logical(~ismember(cell_id, lincs_lines))
            cell_line_is_lincs = false;
        else
            cell_line_is_lincs = true;
        end
        % Get lineage and histology from the API
        q_metadata = cell_query_api('--user_key',api_user_key,'--where',...
            strcat('"cell_id":"',cell_id,'"'));
        
        if isempty(q_metadata)
            cell_lineage = '-666';
            cell_histology = '-666';
        else
            if ismember('cell_lineage',fieldnames(q_metadata))
                if  isempty(q_metadata.cell_lineage)
                    cell_lineage = '-666';
                else
                    cell_lineage = q_metadata.cell_lineage;
                end
            else
                cell_lineage = '-666';
            end
            
            if ismember('cell_histology',fieldnames(q_metadata))
                if isempty(q_metadata.cell_histology)
                    cell_histology = '-666';
                else
                    cell_histology = q_metadata.cell_histology;
                end
            else
                cell_histology = '-666';
            end
        end
    end
    % Get indices of the cell line
    % cell_line_idx = ismember(ds_get_meta(ds_plate_slice,'column','cell_id'),cell_id_annot);
    
    %     % Check if metadata about cell line lineage and histology is in the column annotation
    %     has_lineage = false;
    %     has_histology = false;
    %     if ismember('cell_lineage',ds_plate_slice.chd)
    %         has_lineage = true;
    %         cell_lineages_annot_all = ds_get_meta(ds_plate_slice,'column','cell_lineage');
    %         cell_lineages_annot_all = unique(cell_lineages_annot_all(cell_line_idx));
    %     end
    %     if ismember('cell_histology',ds_plate_slice.chd)
    %         has_histology = true;
    %         cell_histology_annot_all = ds_get_meta(ds_plate_slice,'column','cell_histology');
    %         cell_histology_annot_all = unique(cell_histology_annot_all(cell_line_idx));
    %     end
    %
end

sfds.cell_id = cell_id;
sfds.cell_lineage = cell_lineage;
sfds.cell_histology = cell_histology;
sfds.cell_line_is_guessed = cell_line_is_guessed;
sfds.cell_line_is_missing = cell_line_is_missing;
sfds.cell_line_is_lincs = cell_line_is_lincs;
sfds.cell_line_is_member = cell_line_is_member;


