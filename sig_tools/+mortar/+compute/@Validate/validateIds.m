function pass = validateIds(filelist,varargin)
% Compares a list of files of supported file types [GCT(x), GMT, TXT]
% and ensures the ids match across 


    pnames = {'id_fields'};
    dflts = {{'sig_id', 'distil_id'}};
    args  = parse_args(pnames, dflts, varargin{:});

    ref_set = 0;
    gmt_list = cell(2,1);
    gmt_idx = 1;
    for i = 1:numel(filelist)
        [~,fn,ext] = fileparts(filelist{i});
        switch lower(ext)
            case '.gct'
                ds = parse_gctx(filelist{i});
                ids = ds.cid;
            case '.gctx'
                ds = parse_gctx(filelist{i}, 'annot_only', 1);
                ids = ds.cid;
            case '.gmt'
                gmt_list(gmt_idx) = filelist(i);
                gmt_idx = gmt_idx + 1;
                continue   %skip setting reference to gmt file ids due to suffixes
            case '.txt'
                table = parse_record(filelist{i});
                
                table_fn = fieldnames(table);
                id_field = intersect(table_fn, args.id_fields, 'stable');
                
                ids = {table.(id_field{1})}';
            otherwise
                continue
        end
        if (~ref_set) %set the reference ids
            ref = sort(ids);
            ref_set = 1;
            ref_idx = i;
        else
            assert(numel(ids) == numel(ref), ...
                'Files %s and %s have different dimensions', ...
                filelist{ref_idx}, filelist{i});
            diffs = setxor(ids, ref);
            assert(isempty(diffs), 'Files %s and %s have differences', ...
                filelist{ref_idx}, filelist{i}); 
        end
    end

    if (ref_set && ~any(cellfun(@isempty, gmt_list)))
        for j=1:numel(gmt_list)
            sets = parse_gmt(gmt_list{j});
            ids = sort({sets.head}); 
            ids = regexprep(ids, '(?i)(_up|_dn)', ''); % remove suffixes 
            assert(numel(ids) == numel(ref), ...
                'Files %s and %s have different dimensions', ...
                filelist{ref_idx}, gmt_list{j});
            diffs = ~rematch(ids, ref);
            assert(sum(diffs) == 0, ...
                'Files %s and %s have differences', ...
                filelist{ref_idx}, gmt_list{j});
        end
    end
    pass = filelist;
    
end

