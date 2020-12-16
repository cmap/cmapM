function runAnalysis_(obj, varargin)
% extract subset from dataset
args = obj.getArgs;
wkdir = obj.getWkdir;

fileList = mortar.collate.Generic.getFileList('--files', args.files,...
                       '--folders', args.folders,...
                       '--parent_folder', args.parent_folder,...
                       '--file_wildcard', args.file_wildcard,...
                       '--sub_folder', args.sub_folder,...
                       '--verbose', args.verbose);

outFile =  fullfile(wkdir, 'result.gctx');
% outFile = mortar.collate.Generic.collateDatasets(fileList, args, wkdir);
outFile = mortar.collate.Generic.collateDatasets(...
                          fileList,...
                          outFile,...
                          '--rid', args.rid,...
                          '--cid', args.cid,...
                          '--row_space', args.row_space,...
                          '--block_size', args.block_size,...
                          '--use_compression', args.use_compression,...
                          '--merge_partial', args.merge_partial,...
                          '--missing_value', args.missing_value,...
                          '--verbose', args.verbose);
obj.res_ = struct('args', args,...
                  'file_list', {fileList},...
                  'out_file', outFile);

end

function file_list = getFileList(args)
% Construct file list
dbg(args.verbose, 'Generating file list...');
if ~isempty(args.files)
    file_list = parse_grp(args.files);
    file_list = cellfun(@(x) fullfile(args.parent_folder, x), file_list, 'unif', false);
    isfile = mortar.common.FileUtil.isfile(file_list, 'file');
    if ~all(isfile)
        disp (file_list(~isfile));
        error('%d/%d files not found', nnz(~isfile), numel(isfile));
    end
elseif ~isempty(args.folders)
    folders = parse_grp(args.folders);
    nfolder = length(folders);
    file_list = cell(nfolder, 1);
    for ii=1:nfolder
        p = fullfile(args.parent_folder, folders{ii},...
                args.sub_folder, sprintf('%s', args.file_wildcard));
        [fn, fp] = find_file(p);
        if ~isempty(fn)
            file_list{ii} = fp{1};
        else
            error('%s not found', p)
        end
    end
end
end

function out_file = collateFiles(fileList, args, wkdir)
% collateFiles(fileList) Collate a list of files to disk
nfile = numel(fileList);
if nfile>0    
    out_file = fullfile(wkdir, 'result.gctx');
    nblock = ceil(nfile / args.block_size);
    ncol = 0;
    if ~isempty(args.rid)
        rid = parse_grp(args.rid);
    elseif ~isempty(args.row_space)
        rid = mortar.common.Spaces.probe(args.row_space).asCell;
    else
        rid = '';
    end
    
    if ~isempty(args.cid)
        cid = parse_grp(args.cid);
    else
        cid = '';
    end
    
    dbg(args.verbose, 'Collating %d folders in %d blocks...', nfile, nblock);
    if args.use_compression
        compression = 'gzip';
    else
        compression = 'none';
    end    
    for ii=1:nblock
        dbg(args.verbose, 'Block: %d/%d', ii, nblock);
        st = (ii-1)*args.block_size + 1;
        stp = min(st +args.block_size - 1, nfile);
        outds = merge_profile(fileList(st:stp));
        this_cid = intersect_ord(cid, outds.cid);
        outds = ds_slice(outds, 'cid', this_cid, 'rid', rid);
        this_ncol = length(outds.cid);
        if this_ncol>0
            ncol = ncol + this_ncol;
            mkgctx(out_file, outds,...
                'insert', true,...
                'appenddim', false,...
                'compression', compression,...
                'compression_level', 6);
        else
            dbg(1, 'Skipping empty block');
        end
    end    
    dbg(args.verbose, 'Collated %d columns', ncol);
else
    dbg(args.verbose, 'No valid folders found, skipping');
end
end