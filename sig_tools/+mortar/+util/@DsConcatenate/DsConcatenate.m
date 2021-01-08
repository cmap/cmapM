classdef DsConcatenate
    properties
        fill_for_missing_meta = -666;
        fill_for_missing_data = NaN;
    end
    
    properties(Constant = true)
        cdir_except_msg = 'input parameter concat_direction must be either along-rows or along-columns, it was:  ';
    end

    methods
        function ds = concat(obj, ds_array, concat_direction)
            %function ds = concat(ds_array, concat_direction)
            %concat_direction is either 'along-rows' or 'along-columns'

            cdir = 0;
            if strcmp('along-rows', concat_direction)
                cdir = 1;
            elseif strcmp('along-columns', concat_direction)
                cdir = 2;
            else
                msg = [mortar.util.DsConcatenate.cdir_except_msg concat_direction];
                e = MException('mortar_util_DsConcatenate_concat:unrecognized_concat_direction', msg);
                throw(e)
            end

            %gather metadata into correct arrays based on direction of concatenation
            [concat_meta_desc, concat_meta_hd, concat_meta_ids, common_meta_desc, common_meta_hd, common_meta_ids] = mortar.util.DsConcatenate.transform_ds_array(ds_array, concat_direction);

            [assembled_concat_meta_desc, assembled_concat_meta_hd, assembled_concat_meta_ids] = obj.assemble_concatenated_meta(concat_meta_desc, concat_meta_hd, concat_meta_ids);

            [assembled_common_meta_desc, assembled_common_meta_hd, assembled_common_ids] = mortar.util.DsConcatenate.assemble_common_meta(common_meta_desc, common_meta_hd, {}, common_meta_ids);

            matrices = cellfun(@(x) x.mat, ds_array, 'UniformOutput', false);
            [assembled_matrix, assembled_common_ids2] = obj.assemble_data(matrices, common_meta_ids, concat_direction);

            if cdir == 1
                ds = mkgctstruct(assembled_matrix, 'rid', assembled_concat_meta_ids, 'cid', assembled_common_ids, 'rhd', assembled_concat_meta_hd, 'rdesc', assembled_concat_meta_desc, ...
                    'chd', assembled_common_meta_hd, 'cdesc', assembled_common_meta_desc);
            else
                ds = mkgctstruct(assembled_matrix, 'rid', assembled_common_ids, 'cid', assembled_concat_meta_ids, 'rhd', assembled_common_meta_hd, 'rdesc', assembled_common_meta_desc, ...
                    'chd', assembled_concat_meta_hd, 'cdesc', assembled_concat_meta_desc);
            end
        end

        function [assembled_meta_desc, assembled_meta_hd, assembled_meta_ids] = assemble_concatenated_meta(obj, concat_meta_desc, concat_meta_hd, concat_meta_ids)
            num_ids = sum(cellfun(@(x) length(x), concat_meta_ids));
            num_unique_ids = length(mortar.util.DsConcatenate.calculate_union_of_all(concat_meta_ids));
            if num_unique_ids < num_ids
                num_duplicate_entries = num_ids - num_unique_ids
                msg = ['there cannot be duplicate entries in concat_meta_ids, but there are num_duplicate_entries:  ' num2str(num_duplicate_entries)]
                e = MException('mortar_util_DsConcatenate_assemble_concatenated_meta:duplicate_concat_meta_ids', msg);
                throw(e)
            end

            assembled_meta_hd = sort(mortar.util.DsConcatenate.calculate_union_of_all(concat_meta_hd));
            
            assembled_meta_ids = cell(1, num_ids);
            assembled_meta_desc = cell(num_ids, length(assembled_meta_hd));
            assembled_meta_desc(:) = {obj.fill_for_missing_meta};

            index = 1
            for ii = 1:length(concat_meta_desc)
                cur_meta_desc = concat_meta_desc{ii};
                cur_meta_ids = concat_meta_ids{ii};
                
                cur_meta_hd = concat_meta_hd{ii};
                [~, hd_sort_ind] = sort(cur_meta_hd);

                end_index = index + length(cur_meta_ids) - 1;

                assembled_meta_ids(index:end_index) = cur_meta_ids;

                cur_hd_indexes = ismember(assembled_meta_hd, cur_meta_hd);

                assembled_meta_desc(index:end_index, cur_hd_indexes) = cur_meta_desc(:, hd_sort_ind);

                index = end_index + 1;
            end
        end

        function [combined_matrix, combined_common_ids] = assemble_data(obj, matrices, common_ids, concat_direction)
            %function [combined_matrix, combined_common_ids] = assemble_data(obj, matrices, common_ids, concat_direction)
            %concat_direction is either 'along-rows' or 'along-columns'

            combined_common_ids = sort(mortar.util.DsConcatenate.calculate_union_of_all(common_ids));

            adir = 0;
            if strcmp('along-rows', concat_direction)
                adir = 1;
            elseif strcmp('along-columns', concat_direction)
                adir = 2;
            else
                msg = [mortar.util.DsConcatenate.cdir_except_msg concat_direction];
                e = MException('mortar_util_DsConcatenate_assemble_data:unrecognized_concat_direction', msg);
                throw(e);
            end

            num_along = sum(cellfun(@(x) size(x, adir), matrices));

            combined_matrix_size = [];
            if adir == 1
                combined_matrix_size = [num_along, length(combined_common_ids)];
            else
                combined_matrix_size = [length(combined_common_ids), num_along];
            end 
            combined_matrix = zeros(combined_matrix_size);
            combined_matrix(:) = obj.fill_for_missing_data;

            index = 1;
            for ii = 1:length(matrices)
                cur_matrix = matrices{ii};
                
                cur_ids = common_ids{ii};
                [~, ids_sort_ind] = sort(cur_ids);

                cur_ids_indexes = ismember(combined_common_ids, cur_ids);

                end_index = index + size(cur_matrix, adir) - 1;

                if adir == 1
                    combined_matrix(index:end_index, cur_ids_indexes) = cur_matrix(:, ids_sort_ind);
                else
                    combined_matrix(cur_ids_indexes, index:end_index) = cur_matrix(ids_sort_ind, :);
                end

                index = end_index + 1;
            end
        end
    end

    methods(Static)
        function u = calculate_union_of_all(collection_of_collections)
            u = {};

            for ii = 1:length(collection_of_collections)
                cur_collection = collection_of_collections{ii};
                u = union(u, cur_collection);
            end
        end

        function intersection = calculate_intersection_of_all(collection_of_collections)
            intersection = collection_of_collections{1};

            for ii = 2:length(collection_of_collections)
                cur_collection = collection_of_collections{ii};
                intersection = intersect(intersection, cur_collection);
            end
        end

        function [meta_desc, meta_hd, ids] = assemble_common_meta(common_meta_desc, common_meta_hd, hd_to_remove, common_ids)
            shared_meta_hd = mortar.util.DsConcatenate.calculate_intersection_of_all(common_meta_hd);
            all_meta_hd = mortar.util.DsConcatenate.calculate_union_of_all(common_meta_hd);

            unshared_hd = setdiff(all_meta_hd, shared_meta_hd);

            all_hd_to_remove = union(unshared_hd, hd_to_remove);

            [stripped_common_meta_desc, stripped_common_meta_hd] = mortar.util.DsConcatenate.remove_hd_from_meta_desc(common_meta_desc, common_meta_hd, all_hd_to_remove);

            [meta_desc, meta_hd, ids] = mortar.util.DsConcatenate.build_union_meta(stripped_common_meta_desc, stripped_common_meta_hd, common_ids);
        end

        function [stripped_common_meta_desc, stripped_common_meta_hd] = remove_hd_from_meta_desc(common_meta_desc, common_meta_hd, hd_to_remove)
            stripped_common_meta_desc = cell(size(common_meta_desc));
            stripped_common_meta_hd = cell(size(common_meta_hd));

            for jj = 1:length(common_meta_desc)
                desc = common_meta_desc{jj};
                hd = common_meta_hd{jj};

                hd_keep_bool = ~ismember(hd, hd_to_remove);

                stripped_common_meta_desc{jj} = desc(:, hd_keep_bool);
                stripped_common_meta_hd{jj} = hd(hd_keep_bool);
            end
        end

        function [union_meta_desc, union_meta_hd, union_ids] = build_union_meta(common_meta_desc, common_meta_hd, common_ids)
            num_ids = length(mortar.util.DsConcatenate.calculate_union_of_all(common_ids)); %NB just getting the length here because we
            %need to collect the id's as we go below so they match the meta_desc
            num_hds = length(mortar.util.DsConcatenate.calculate_union_of_all(common_meta_hd));  %NB same logic as above

            unsorted_union_ids = {};
            union_meta_hd = cell(1, num_hds);
            unsorted_union_meta_desc = cell(num_ids, num_hds);

            index = 1;
            for ii = 1:length(common_meta_desc)
                cur_ids = common_ids{ii};

                to_add_ids = setdiff(cur_ids, unsorted_union_ids);

                if ~isempty(to_add_ids)
                    row_indexes = ismember(cur_ids, to_add_ids);
                    end_index = index + sum(row_indexes) - 1;

                    unsorted_union_ids(index:end_index) = cur_ids(row_indexes);

                    cur_meta_desc = common_meta_desc{ii};
                    [union_meta_hd, sort_ind] = sort(common_meta_hd{ii});

                    unsorted_union_meta_desc(index:end_index, :) = cur_meta_desc(row_indexes, sort_ind);
                    index = end_index + 1;
                end
            end

            [union_ids, union_ids_sort_ind] = sort(unsorted_union_ids);
            union_meta_desc = unsorted_union_meta_desc(union_ids_sort_ind, :);
        end

        function [concat_meta_desc, concat_meta_hd, concat_meta_ids, common_meta_desc, common_meta_hd, common_meta_ids] = transform_ds_array(ds_array, concat_direction)
             if strcmp('along-rows', concat_direction)
                concat_meta_desc_fun = @(x) x.rdesc;
                concat_meta_hd_fun = @(x) x.rhd;
                concat_meta_ids_fun = @(x) x.rid;
                common_meta_desc_fun = @(x) x.cdesc;
                common_meta_hd_fun = @(x) x.chd;
                common_meta_ids_fun = @(x) x.cid;
            elseif strcmp('along-columns', concat_direction)
                concat_meta_desc_fun = @(x) x.cdesc;
                concat_meta_hd_fun = @(x) x.chd;
                concat_meta_ids_fun = @(x) x.cid;
                common_meta_desc_fun = @(x) x.rdesc;
                common_meta_hd_fun = @(x) x.rhd;
                common_meta_ids_fun = @(x) x.rid;
            else
                msg = [mortar.util.DsConcatenate.cdir_except_msg concat_direction];
                e = MException('mortar_util_DsConcatenate_transform_ds_array:unrecognized_concat_direction', msg);
                throw(e);
            end
            concat_meta_desc = cellfun(concat_meta_desc_fun, ds_array, 'UniformOutput', false);
            concat_meta_hd = cellfun(concat_meta_hd_fun, ds_array, 'UniformOutput', false);
            concat_meta_ids = cellfun(concat_meta_ids_fun, ds_array, 'UniformOutput', false);
            common_meta_desc = cellfun(common_meta_desc_fun, ds_array, 'UniformOutput', false);
            common_meta_hd = cellfun(common_meta_hd_fun, ds_array, 'UniformOutput', false);
            common_meta_ids = cellfun(common_meta_ids_fun, ds_array, 'UniformOutput', false);
        end
    end
end

