function sigQuery(varargin)
% SigQuery Collate query results from multiple sig_query_tool runs.
 
% TODO

    import mortar.util.Message
    [args, help_flag] = get_args(varargin{:});
    
    if ~help_flag
        
        t0 = tic;
        %% Generate list of folders to collate
        Message.debug(args.verbose, 'Generating result list...');
        [fn, fp] = find_file(args.src_path);
        not_dot = ~ismember(fn, {'.', '..'});
        src_list = fp(not_dot);
        fn = fn(not_dot);
        is_dir = mortar.common.FileUtil.isfile(src_list, 'dir');
        src_list = src_list(is_dir);
        fn = fn(is_dir);
        nsrc = length(src_list);
        Message.debug(args.verbose, 'Found %d result folders', nsrc);
  
        if ~isempty(args.src_list)
            src_list_filter = mortar.containers.List(args.src_list);
            fn_filter = cellfun(@(x) fileparts(x), src_list_filter.asCell, 'unif', ...
                                false);
            [fn, fnidx] = intersect(fn, fn_filter);
            nfilt = length(fn);
            Message.debug(args.verbose, ['Applied src filter, keeping ' ...
                                '%d/%d folders'], nfilt, nsrc);
            src_list = src_list(fnidx);
            nsrc = length(src_list);
        end

        %% Check folders for valid output
        
        if nsrc
            Message.debug(args.verbose, 'Verifying result folders...');
            
            if args.merge_minimal
                suffix = {'COMBINED'};
            else
                suffix = {'COMBINED','UP','DN'};
            end
            nsuffix = length(suffix);
            isok = false(nsrc, 1);
            merge_list = cell(nsrc, nsuffix);
            for ii=1:nsrc
                isok(ii) = mortar.util.File.isfile(fullfile(src_list{ii}, 'done.grp'), 'file');
                if isok(ii)
                    for jj=1:nsuffix                       
                        [~, res_path] = find_file(fullfile(src_list{ii}, sprintf('result_*.%s*.gct*',suffix{jj})));
                        assert(~isempty(res_path), 'result matrix (%s) not found in %s', suffix{jj}, src_list{ii});
                        merge_list{ii, jj} = res_path{1};
                    end
                end
            end
            if ~isequal(nnz(isok), nsrc)
                Message.debug(args.verbose, '%d/%d folders were incomplete or invalid, ignoring them.', nnz(isok), nsrc);
                disp(src_list(~isok));
                merge_list = merge_list(isok,:);
                src_list = src_list(isok);
                nsrc = length(src_list);        
            end    
        end

        if nsrc
            %% collate results            
            for jj=1:nsuffix
                mkgrp(fullfile(args.out, sprintf('merge_list_%s.grp', suffix{jj})),...
                    merge_list(:, jj));
                [~, file_prefix] = fileparts(merge_list{1, jj});
                out_file = fullfile(args.out, [strip_dimlabel(file_prefix), '.gctx']);
                nblock = ceil(nsrc / args.block_size);
                nquery = 0;
                Message.debug(args.verbose, 'Collating %d folders in %d blocks...', nsrc, nblock);
                
                if args.compress
                    compression = 'gzip';
                else
                    compression = 'none';
                end
                
                for ii=1:nblock
                    Message.debug(args.verbose, 'BLOCK: %d/%d', ii, nblock);
                    st = (ii-1)*args.block_size + 1;
                    stp = min(st +args.block_size - 1, nsrc);
                    outds = merge_profile(merge_list(st:stp, jj));
                    nquery = nquery + length(outds.cid);
                    mkgctx(out_file, outds,...
                        'insert', true,...
                        'appenddim', false,...
                        'compression', compression,...
                        'compression_level', args.compression_level);
                end
            end
            % add annotations if provided
            if ~isempty(args.col_meta)
                % read one row and annotate all columns
                ds = parse_gctx(out_file, 'rid', outds.rid(1));
                ds = ds_annotate(ds, args.col_meta,...
                            'dim', 'column',...
                            'keyfield',  args.col_meta_field);
                mkgctx(out_file, ds,...
                            'insert', true,...
                            'appenddim', false,...
                            'compression', compression,...
                            'compression_level', args.compression_level);
            end            
            if ~isempty(args.row_meta)
                % read one column and annotate all rows
                ds = parse_gctx(out_file, 'cid', outds.cid(1));
                ds = ds_annotate(ds, args.row_meta,...
                    'dim', 'row',...
                    'keyfield',  args.row_meta_field);
                mkgctx(out_file, ds,...
                    'insert', true,...
                    'appenddim', false,...
                    'compression', compression,...
                    'compression_level', args.compression_level);
            end
            
            tend = toc(t0);
            mkgrp(fullfile(args.out, 'done.grp'),  {sprintf('%2.2fs', ...
                tend)})
            
            Message.debug(args.verbose, 'Collated %d queries in %2.1f s', ...
                nquery, tend);
        else
            Message.debug(args.verbose, 'No valid folders found, skipping');
        end
        Message.debug(args.verbose, 'END');    
    end
end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));

opt = struct('prog', mfilename,...
             'desc', 'Collate sig_query result folders',...
             'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    % validate inputs
    assert(~isempty(args.src_list) || ~isempty(args.src_path),...
            'No source path or list specified');
    
    % work dir
    if args.mkdir
        wkdir = mktoolfolder(args.out, mfilename, 'prefix', args.rpt);
    else
        if isempty(args.out)
            args.out = pwd;
        end
        wkdir = args.out;
        if ~isdirexist(wkdir)
            mkdir(wkdir);
        end
    end
    
    args_save = args;
    % handle remote URLs
    args = get_config_url(args, wkdir, true);
    
    % save config with remote URLS if applicable
    WriteYaml(fullfile(wkdir, 'config.yaml'), args_save);
    args.out = wkdir;
end
end
