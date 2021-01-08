function ds = ds_concatenate(ds_array, varargin)
% function ds = ds_concatenate(ds_array, varargin)
% DS_CONCATENATE concatenate multiple datasets (in ds_array)
% specify direction to concatenate via varagin 'concat_direction':  along-rows or along-columns
% For either mode, all matrix data is kept, mismatches between RID/CID in datasets are filled with NaN (by default - see option --missing_data_fill) 
% For meta data in the concat_direction, mismatches between RID/CID are filled with -666 (by default - see option --missing_metadata_fill)
% For meta data in common (opposite of concat_direction), only metadata that is in common to all datasets is kept
%
% see ds_concatenate_default_params.arg for description of varargin options
% 
% example:  combining datasets along-columns is equivalent to appending the columns of the datasets onto the first dataset
%   in this example, the concat_direction is along-columns.  All column metadata is kept, and if for example the first 
%   dataset has column metadata headers cm1, cm2, but the second only has cm1, then values of -666 are filled in for cm2 for the
%   metadata for the columns from the second dataset.
%   For the row metadata, if dataset 1 has metadata headers rm1, rm2, rm3, and dataset 2 has metadata headers rm2, rm3, rm4,
%   the metadata returned will just have rm2 and rm3 (the ones in common between these 2 datasets)

    config = struct('name', {'--concat_direction', ...
                            '--missing_metadata_fill', ...
                            '--missing_data_fill'}, ...
        'default', {'along-columns', ...
                    -666, ...
                    NaN}, ...
        'choices', {{'along-columns', 'along-rows'}, ...
                    {}, ...
                    {}}, ...
        'help', {'specify the direction to combine (concatenate) datasets and then fill in missing entries resulting dataset with missing_data_fill (default: NaN)', ...
        'value to use when filling in missing metadata', ...
        'value to use when filling in missing matrix entries'});

    opt = struct('prog', mfilename, 'desc', 'Run ds_concatenate.m');
    args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

    my_dscc = mortar.util.DsConcatenate();

    my_dscc.fill_for_missing_meta = args.missing_metadata_fill;
    my_dscc.fill_for_missing_data = args.missing_data_fill;

    if length(ds_array) < 2
        msg = ['need to have at least two datasets provided in input ds_array, but length(ds_array): ' num2str(length(ds_array))];
        error('ds_concatenate:need_at_least_2_ds', msg);
    else
        ds = my_dscc.concat(ds_array, args.concat_direction);
    end
end
