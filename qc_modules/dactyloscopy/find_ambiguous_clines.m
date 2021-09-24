function out = find_ambiguous_clines(cell_id,best_cell_id,best_lincs_cell_id,...
    ambig_clines_table)
%% FIND_AMBIGUOUS_CLINES Function to check if a pair of cell lines is on 
%           a list of pairs of cell lines that hard to distinguish
%   out = find_ambiguous_clines(cell_id,best_cell_id,best_lincs_cell_id,...
%    ambig_clines_struct)
%
% Input:
%   cell_id - cell_id of the cell line on a plate
%   best_cell_id - a cell line from the reference libraryr with the highest rank
%   best_lincs_cell_id - a LINCS cell line with the highest rank
%   ambig_clines_struct - a structure that represents a table where each
%       record contains two cell ids of ambiguous cell lines and a value of
%       Spearman correlation coefficient (table header two of the columns 
%       has to contain: cell_id1, cell_id2)
% Output:
%   out - logical variable wheter a pair of cell lines is on the list or
%           not
% Example:
%   out = find_ambiguous_clines('HS751T','HS274T','HS27',ambiguous_clines_structure)
%
% E-mail: Marek Orzechowski morzech@broadinstitute.org

n_ambig = size(ambig_clines_table, 1);
input_pair_clines_best = {cell_id,best_cell_id};
input_pair_clines_best_lincs = {cell_id,best_lincs_cell_id};
out = false;

for ii = 1:n_ambig
    if isequal(cell_id,best_cell_id)
        out = true;
    else
        is_memb_best = ismember(input_pair_clines_best,...
            [ambig_clines_table.cell_id1(ii),ambig_clines_table.cell_id2(ii)]);
        is_memb_best_lincs = ismember(input_pair_clines_best_lincs,...
            [ambig_clines_table.cell_id1(ii),ambig_clines_table.cell_id2(ii)]);
        is_ambig_best = sum(is_memb_best);
        is_ambig_best_lincs = sum(is_memb_best_lincs);
        if is_ambig_best==2
            out = true;
        elseif is_ambig_best_lincs==2
            out = true;
        end
    end
end

