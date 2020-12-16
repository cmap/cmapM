function dsfile = mkgctx(dsfile, ds, varargin)
% MKGCTX Save an annotated matrix in GCTX format.
% MKGCTX(DSFILE, DS)
% MKGCTX(DSFILE, DS, 'param', value, ...) Specify optional parameters
%   Parameter       Value
%   'appenddim'     Append matrix dimensions to filename if true. Default is true
%   'compression'   Specify data compression algorithm {['none'], 'gzip'}.
%                   Note that using compression will create small files at
%                   the expense of read performance.
%   'compression_level' Compression level [0-9], only used if 'gzip' compression
%                       is specified. Default is 6
%   'overwrite'     Overwrite data if true. Default is false
%   'root'          Root group location in the GCTX file. Default is '0'
%   'dsname'        Data matrix location. Default is '0'
%   'chunk_size' []
%   'cid' ''
%   'compress_meta' Compress metadata if true. false
%   'fill' false
%   'insert' Insert rows / columns to an existing GCTX file. Default is false
%   'insert_dim' ''
%   'max_chunk_kb' 1024
%   'name' 'unnamed'
%   'rid' ''
%   'update' Update values in an existing GCTX file if true. Default is false
%   'verbose' Print debugging messages if true. Default is false
%   'version' GCTX version string. The only valid value is 'GCTX1.0'

% Note: assumes data matrix is at single precision

pnames = {'root', 'dsname', 'name',...
    'compression', 'compression_level'...
    'max_chunk_kb', 'overwrite', 'version',...
    'rid', 'cid', 'insert',...
    'appenddim','update', 'verbose',...
    'fill', 'chunk_size', 'compress_meta',...
    'insert_dim', 'matrix_class',...
    'checkid'};
dflts = {'0','0','unnamed',...
    'none', 6,...
    1024, false, 'GCTX1.0',...
    '', '', false,...
    true, false, false,...
    false, [], true,...
    '', 'single',...
    true};
args = parse_args(pnames, dflts, varargin{:});

check_dup_id(ds.cid, args.checkid);
check_dup_id(ds.rid, args.checkid);

tic
if args.insert || args.update
    if ~isfileexist(dsfile)
        mkgctx(dsfile, ds, varargin{:}, 'insert', false, 'update', false);
    else
        fprintf ('Upserting data to: %s...\n', dsfile);
        insert_ds(dsfile, ds, args)
    end
elseif args.fill
    assert(isnumeric(ds), 'ds should be set to a fill value');
    assert(~isempty(args.rid) && ~isempty(args.cid), 'rid and cid must not be empty');
    nr = length(args.rid);
    nc = length(args.cid);
    [p, f] = fileparts(dsfile);
    if args.appenddim
        %strip old dimension if it exists
        prefix = rm_filedim(f);
        dsfile = fullfile(p, sprintf('%s_n%dx%d.gctx', prefix, nc, ...
            nr));
    else
        dsfile = fullfile(p, [f, '.gctx']);
    end
    fprintf ('Saving HDF5 dataset to: %s...\n', dsfile);
    if ~isfileexist(dsfile) || args.overwrite
        fcpl = H5P.create('H5P_FILE_CREATE');
        fapl = H5P.create('H5P_FILE_ACCESS');
        file = H5F.create(dsfile, 'H5F_ACC_TRUNC', fcpl, fapl);
        set_scalar_attr(file, 'version', args.version)
    elseif isfileexist(dsfile)
        file = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    end
    %create groups for annotations
    rdesc = '';
    rhd = '';
    cdesc = '';
    chd = '';
    write_annot(file, sprintf('/%s/META/ROW', args.root), args.rid, rdesc, rhd, args)
    write_annot(file, sprintf('/%s/META/COL/', args.root), args.cid, cdesc, chd, args)
    
    %create data group
    write_scalar(file, args.root, args.dsname, nr, nc, ds, args)
    H5F.close(file);
    
    fprintf ('done [%2.2fs].\n', toc);
else
    if ~isempty(args.rid)
        args.rid = parse_grp(args.rid);
    end
    if ~isempty(args.cid)
        args.cid = parse_grp(args.cid);
    end
    
    ds = reorder_ds(ds, args.rid, args.cid);
    [nr,nc] = size(ds.mat);
    [p, f] = fileparts(dsfile);
    if args.appenddim        
        %strip old dimension if it exists
        prefix = rm_filedim(f);
        dsfile = fullfile(p, sprintf('%s_n%dx%d.gctx', prefix, nc, nr));
    else
        dsfile = fullfile(p, [f, '.gctx']);
    end
    fprintf ('Saving HDF5 dataset to: %s...\n', dsfile);
    if ~isfileexist(dsfile) || args.overwrite
        fcpl = H5P.create('H5P_FILE_CREATE');
        fapl = H5P.create('H5P_FILE_ACCESS');
        file = H5F.create(dsfile, 'H5F_ACC_TRUNC', fcpl, fapl);
        set_scalar_attr(file, 'version', args.version)
    elseif isfileexist(dsfile)
        file = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    end
    %create groups for annotations
    write_annot(file, sprintf('/%s/META/ROW', args.root), ds.rid, ds.rdesc, ds.rhd, args)
    write_annot(file, sprintf('/%s/META/COL/', args.root), ds.cid, ds.cdesc, ds.chd, args)
    
    %create data group
    write_matrix(file, args.root, args.dsname, ds.mat, args)
    
    H5F.close(file);
end
fprintf ('done [%2.2fs].\n', toc);
end

function insert_ds(dsfile, ds, args)
% Insert columns into an existing GCTX file

annot = parse_gctx(dsfile, 'annot_only', true);
if isempty(args.insert_dim)
    % try and guess the dimension
    annot2 = parse_gctx(ds, 'annot_only', true);
    [tf, insert_dim] = is_ds_mergeable(annot, annot2);
    assert(tf, 'Cannot insert data, dimensions are incompatible');
else
    assert(any(ismember(args.insert_dim, {'row', 'column'})),...
        'Invalid insert dimension: %s', args.insert_dim);
    insert_dim = args.insert_dim;
end

switch insert_dim
    case 'column'
        % reorder rows to match
        ds = gctextract_tool(ds, 'rid', annot.rid);
        
        % look up table for cids in dsfile
        dsfile_lut = list2dict(annot.cid);
        in_dsfile = dsfile_lut.isKey(ds.cid);
        
        % new samples
        ncidx = ~in_dsfile;
        ncid = ds.cid(ncidx);
        
        % existing samples
        ecidx_ds = in_dsfile;
        ecid = ds.cid(ecidx_ds);
        ecidx_annot = cell2mat(dsfile_lut.values(ecid));
        
        if ~isempty(ecid) || ~isempty(ncid)
            
            fid = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            %UPDATES
            if ~isempty(ecid)
                if args.update
                    update_matrix(fid, args.root, args.dsname,...
                        ds.mat(:, ecidx_ds), ecidx_annot, insert_dim, args);
                else
                    %disp(ecid);
                    dbg(args.verbose, 'Ignoring %d/%d samples that already exist in dsfile', ...
                        length(ecid), length(ds.cid))
                end
            end
            
            %INSERTS
            if ~isempty(ncid)
                insert_matrix(fid, args.root, args.dsname, ds.mat(:, ncidx), insert_dim, args);
            end
            
            % Column annotations
            newcid = [annot.cid; ncid];
            if isequal(annot.chd, ds.chd) && ~args.update
                % annotations in same order, simply append
                newchd = annot.chd;
                if ~isempty(newchd)
                    newcdesc = [annot.cdesc; ds.cdesc(ncidx,:)];
                else
                    newcdesc = {};
                end
            else
                % handle mismatch in number or order of annotations
                newchd = union(annot.chd, ds.chd);
                newcdesc = cell(length(newcid), length(newchd));
                % copy annotations for existing samples
                [~, chidx_annot, chidx_new1] = intersect_ord(annot.chd, newchd);
                if ~isempty(chidx_annot)
                    newcdesc(1:length(annot.cid),chidx_new1) = annot.cdesc(:, chidx_annot);
                end
                % append new annotations
                [~, chidx_ds, chidx_new2] = intersect_ord(ds.chd, newchd);
                if ~isempty(chidx_ds)
                    newcdesc(length(annot.cid)+(1:length(ncid)), chidx_new2) = ...
                        ds.cdesc(ncidx, chidx_ds);
                    % update existing annotations
                    if args.update
                        newcdesc(ecidx_annot, chidx_new2) = ds.cdesc(ecidx_ds, chidx_ds);
                    end
                end
            end
            if ~isempty(ncid) || args.update
                write_annot(fid, sprintf('/%s/META/COL', args.root), newcid, newcdesc, newchd, args)
            end
            H5F.close(fid);
        end
        
    case 'row'
        % reorder columns to match
        ds = gctextract_tool(ds, 'cid', annot.cid);
        
        % look up table for rids in dsfile
        dsfile_lut = list2dict(annot.rid);
        in_dsfile = dsfile_lut.isKey(ds.rid);
        
        % new samples
        nridx = ~in_dsfile;
        nrid = ds.rid(nridx);
        
        % existing samples
        eridx_ds = in_dsfile;
        erid = ds.rid(eridx_ds);
        eridx_annot = cell2mat(dsfile_lut.values(erid));
        
        if ~isempty(erid) || ~isempty(nrid)
            
            fid = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            % UPDATES
            if ~isempty(erid)
                if args.update
                    update_matrix(fid, args.root, args.dsname,...
                        ds.mat(eridx_ds, :), eridx_annot, insert_dim, args);
                else
                    %disp(ecid);
                    dbg(args.verbose, 'Ignoring %d/%d samples that already exist in dsfile', ...
                        length(erid), length(ds.rid))
                end
            end
            
            % INSERTS
            if ~isempty(nrid)
                insert_matrix(fid, args.root, args.dsname, ds.mat(nridx, :), insert_dim, args);
            end
            
            % Row annotations
            newrid = [annot.rid; nrid];
            if isequal(annot.rhd, ds.rhd) && ~args.update
                % annotations in same order, simply append
                newrhd = annot.rhd;
                if ~isempty(newrhd)
                    newrdesc = [annot.rdesc; ds.rdesc(nridx, :)];
                else
                    newrdesc = {};
                end
            else
                % handle mismatch in number or order of annotations
                newrhd = union(annot.rhd, ds.rhd);
                newrdesc = cell(length(newrid), length(newrhd));
                % copy annotations for existing samples
                [~, rhidx_annot, rhidx_new1] = intersect_ord(annot.rhd, newrhd);
                if ~isempty(rhidx_annot)
                    newrdesc(1:length(annot.rid),rhidx_new1) = annot.rdesc(:, rhidx_annot);
                end
                % append new annotations
                [~, rhidx_ds, rhidx_new2] = intersect_ord(ds.rhd, newrhd);
                if ~isempty(rhidx_ds)
                    newrdesc(length(annot.rid)+(1:length(nrid)), rhidx_new2) = ...
                        ds.rdesc(nridx, rhidx_ds);
                    % update existing annotations
                    if args.update
                        newrdesc(eridx_annot, rhidx_new2) = ds.rdesc(eridx_ds, rhidx_ds);
                    end
                end
            end
            if ~isempty(nrid) || args.update
                write_annot(fid, sprintf('/%s/META/ROW', args.root), newrid, newrdesc, newrhd, args)
            end
            H5F.close(fid);
        end
    otherwise
        error('Unknown dimension: %s, expected {''row'', ''column''}', insert_dim);
end

end

function write_scalar(fid, root, mid, nr, nc, fill_value, args)
% write a dataset filled with a specified value

dims = [nr, nc];
% % 1Mb chunks
% max_chunk_kb = 1024;
% compression_type = 'gzip';
% compression_level = 6;
if ~isempty(args.matrix_class)
    fill_value = cast(fill_value, args.matrix_class);
end
h5_datatype = get_matrix_datatype(class(fill_value));

gpname = sprintf('/%s/DATA/%s', root, mid);
% delete link if it exists
if islinkexists(fid, gpname)
    fprintf ('%s exists, deleting\n', gpname);
    H5L.delete(fid, gpname, 'H5P_DEFAULT');
end
% create DATA/GCT group
gcpl = H5P.create ('H5P_LINK_CREATE');
H5P.set_create_intermediate_group (gcpl, 1);
gid = H5G.create (fid, gpname, gcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');

% Create dataspace.  Setting maximum size to [] sets the maximum
% size to be the current size.  Remember to flip the dimensions.
maxdims = fliplr([dims(1) H5ML.get_constant_value('H5S_UNLIMITED')]);
space = H5S.create_simple (2, fliplr(dims), maxdims);

if ~isempty(args.chunk_size)
    chunk_size = args.chunk_size;
else
    chunk_size = get_chunk_size(h5_datatype.elem_per_kb, dims, args.max_chunk_kb);
end
dcpl = set_compression(args.compression, args.compression_level, chunk_size);

% set fill value
type_id = H5T.copy(h5_datatype.filetype);
H5P.set_fill_value(dcpl, type_id, fill_value);

% Create the dataset.
dset = H5D.create(gid, 'matrix', h5_datatype.filetype, space, dcpl);

set_scalar_attr(dset, 'row_major', int32(0))
set_scalar_attr(dset, 'name', args.name);

% Close and release resources.
H5P.close(dcpl);
H5D.close(dset);
H5S.close(space);

H5G.close(gid);
end

function chunk_size = get_chunk_size(elem_per_kb, dims, max_chunk_kb)
% Auto chunk size
% row chunk [1, 1000]
row_size = clip(dims(1), 1, 1000);
% column chunk, such that row * col =< max_chunk_kb
col_size = clip(floor((max_chunk_kb * elem_per_kb) / row_size), 1, dims(2));

%     chunk_size = [dims(1), min(max(floor((max_chunk_kb * elem_per_kb) / dims(1)), 10), dims(2))];
chunk_size = [row_size, col_size];
end

function ds = reorder_ds(ds, rid, cid)
if ~isempty(rid)
    [~, ridx] = intersect_ord(ds.rid, rid);
    ds.mat = ds.mat(ridx,:);
    if ~isempty(ds.rdesc)
        ds.rdesc = ds.rdesc(ridx,:);
    end
end
if ~isempty(cid)
    [~, cidx] = intersect_ord(ds.cid, cid);
    ds.mat = ds.mat(:, cidx);
    if ~isempty(ds.cdesc)
        ds.cdesc = ds.cdesc(cidx,:);
    end
end

end

function update_matrix(fid, root, mid, mat, idx, dim_str, args)
% update samples in existing data matrix

dims = size(mat);
if ~isempty(args.matrix_class)
    mat = cast(mat, args.matrix_class);
end
h5_datatype = get_matrix_datatype(class(mat));
gpname = sprintf('/%s/DATA/%s', root, mid);
gid = H5G.open(fid, gpname);
dset_id = H5D.open(gid, 'matrix', 'H5P_DEFAULT');
file_space_id = H5D.get_space(dset_id);
% Current dimensions, h5_dims: ncols x nrows
[~, h5_dims, ~] = H5S.get_simple_extent_dims(file_space_id);
% matlab_dims: nrows x ncols
matlab_dims = fliplr(h5_dims);

switch dim_str
    case 'column'
        % row extents should match
        if ~isequal(dims(1), matlab_dims(1))
            error('Row size mismatch (is %d expected %d)', dims(1), matlab_dims(1))
        end
        nc = length(idx);
        file_space_id = H5D.get_space(dset_id);
        % dimensions of data to insert as nrows x ncols
        insert_dims = [matlab_dims(1), 1];
        mem_space_id = H5S.create_simple(2, fliplr(insert_dims), []);
        
        dbg(args.verbose, 'Updating %d columns', dims(2));
        % insert columns
        for ii=1:nc
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', ...
                [idx(ii)-1 0], [], fliplr(insert_dims), []);
            H5D.write(dset_id, h5_datatype.filetype, mem_space_id, file_space_id,...
                'H5P_DEFAULT', mat(:,ii))
        end
        
    case 'row'
        
        % column extents should match
        if ~isequal(dims(2), matlab_dims(2))
            error('Column size mismatch (is %d expected %d)', dims(2), matlab_dims(2))
        end
        nr = length(idx);
        file_space_id = H5D.get_space(dset_id);
        insert_dims = [1, matlab_dims(2)];
        mem_space_id = H5S.create_simple(2, fliplr(insert_dims), []);
        
        dbg(args.verbose, 'Updating %d rows', dims(1));
        % insert rows
        for ii=1:nr
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', ...
                [0, idx(ii)-1], [], flipls(insert_dims), []);
            H5D.write(dset_id, h5_datatype.filetype, mem_space_id, file_space_id,...
                'H5P_DEFAULT', mat(ii, :))
        end
end
H5D.close(dset_id);
end

function insert_matrix(fid, root, mid, mat, dim_str, args)
% Insert samples into existing data matrix
dims = size(mat);
if ~isempty(args.matrix_class)
    mat = cast(mat, args.matrix_class);
end
gpname = sprintf('/%s/DATA/%s', root, mid);
h5_datatype = get_matrix_datatype(class(mat));
gid = H5G.open(fid, gpname);
dset_id = H5D.open(gid, 'matrix', 'H5P_DEFAULT');
file_space_id = H5D.get_space(dset_id);
% Current dimensions
[~, h5_dims, ~] = H5S.get_simple_extent_dims(file_space_id);
% matlab_dims: rows x cols
matlab_dims = fliplr(h5_dims);

switch dim_str
    case 'column'
        % Change dimensions
        newdims = [matlab_dims(1), matlab_dims(2) + dims(2)];
        H5D.set_extent(dset_id, fliplr(newdims));
        H5S.close(file_space_id);
        
        dbg(args.verbose, 'Inserting %d columns, newdim:%dx%d', dims(2), newdims(1), newdims(2));
        
        % write matrix into new space
        file_space_id = H5D.get_space(dset_id);
        mem_space_id = H5S.create_simple(2, fliplr(dims), []);
        H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', ...
            [matlab_dims(2) 0], [], [dims(2) matlab_dims(1)], []);
        H5D.write(dset_id, h5_datatype.filetype, ...
            mem_space_id, file_space_id, 'H5P_DEFAULT', ...
            mat);
    case 'row'
        % Change dimensions
        newdims = [matlab_dims(1)+dims(1), matlab_dims(2)];
        H5D.set_extent(dset_id, fliplr(newdims));
        H5S.close(file_space_id);
        
        dbg(args.verbose, 'Inserting %d rows, newdim:%dx%d', dims(1), newdims(1), newdims(2));
        
        % write matrix into new space
        file_space_id = H5D.get_space(dset_id);
        mem_space_id = H5S.create_simple(2, fliplr(dims), []);
        H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', ...
            [0, matlab_dims(1)], [], [matlab_dims(2), dims(1)], []);
        H5D.write(dset_id, h5_datatype.filetype, ...
            mem_space_id, file_space_id, 'H5P_DEFAULT', ...
            mat);
end
H5D.close(dset_id);

end

function write_matrix(fid, root, mid, mat, args)
% write data matrix
dims = size(mat);
% % 1Mb chunks
% max_chunk_kb = 1024;
% compression_type = 'gzip';
% compression_level = 6;
if ~isempty(args.matrix_class)
    mat = cast(mat, args.matrix_class);
end
h5_datatype = get_matrix_datatype(class(mat));
dbg(args.verbose, 'Writing matrix with dimensions [%dx%d]', dims(1), ...
    dims(2));
gpname = sprintf('/%s/DATA/%s', root, mid);
% delete link if it exists
if islinkexists(fid, gpname)
    fprintf ('%s exists, deleting\n', gpname);
    H5L.delete(fid, gpname, 'H5P_DEFAULT');
end
% create DATA/GCT group
gcpl = H5P.create ('H5P_LINK_CREATE');
H5P.set_create_intermediate_group (gcpl, 1);
gid = H5G.create (fid, gpname, gcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');

% Create dataspace.  Setting maximum size to [] sets the maximum
% size to be the current size.  Remember to flip the dimensions.
maxdims = fliplr([H5ML.get_constant_value('H5S_UNLIMITED'),...
    H5ML.get_constant_value('H5S_UNLIMITED')]);
space = H5S.create_simple (2, fliplr(dims), maxdims);

if ~isempty(args.chunk_size)
    chunk_size = args.chunk_size;
else
    chunk_size = get_chunk_size(h5_datatype.elem_per_kb, dims, args.max_chunk_kb);
end
dcpl = set_compression(args.compression, args.compression_level, chunk_size);

% Create the dataset.
dset = H5D.create(gid, 'matrix', h5_datatype.filetype, space, dcpl);

% Write the data to the dataset.
H5D.write(dset, h5_datatype.filetype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', mat);
set_scalar_attr(dset, 'row_major', int32(0))
set_scalar_attr(dset, 'name', args.name);

% Close and release resources.
H5P.close(dcpl);
H5D.close(dset);
H5S.close(space);

%row and column ids
% write_column(gid, 'row_ids', ds.rid);
% write_column(gid, 'column_ids', ds.cid);

H5G.close(gid);
end

function dcpl = set_compression(compression, compression_level, chunk_size, verbose)
% Create the dataset creation property list, add the gzip
% compression filter and set the chunk size.  Remember to flip
% the chunksize.
if ~isdefined('verbose')
    verbose=1;
end
dcpl = H5P.create('H5P_DATASET_CREATE');
h5filters = containers.Map({'gzip', 'szip'}, {'H5Z_FILTER_DEFLATE', 'H5Z_FILTER_SZIP'});
switch compression
    case 'none'
        dbg (verbose, 'Disabling compression.');
    case h5filters.keys
        dbg(verbose, 'Setting compression to: %s (level:%d)', upper(compression), compression_level);
        % Check if compression is available and can be used for both
        % compression and decompression.
        
        if ~H5Z.filter_avail(h5filters(compression))
            error ('%s filter not available.\n', compression);
        end
        
        % Check that it can be used.
        H5Z_FILTER_CONFIG_ENCODE_ENABLED = H5ML.get_constant_value('H5Z_FILTER_CONFIG_ENCODE_ENABLED');
        H5Z_FILTER_CONFIG_DECODE_ENABLED = H5ML.get_constant_value('H5Z_FILTER_CONFIG_DECODE_ENABLED');
        filter_info = H5Z.get_filter_info(h5filters(compression));
        if ( ~bitand(filter_info,H5Z_FILTER_CONFIG_ENCODE_ENABLED) || ...
                ~bitand(filter_info,H5Z_FILTER_CONFIG_DECODE_ENABLED) )
            error ('%s filter not available for encoding and decoding.', compression);
        end
        % set compression and chunking parameters
        H5P.set_deflate (dcpl, compression_level);
    otherwise
        error ('Unknown Compression type: %s', compression)
end

dbg(verbose, 'Setting chunk size to: %s',...
    print_dlm_line(chunk_size, 'dlm', 'x'));
H5P.set_chunk (dcpl, fliplr(chunk_size));

end

function status = islinkexists(fid, gpname)
l = tokenize(regexprep(gpname,'^/',''), '/');
nl = length(l);
status = 1;
for ii=1:nl
    p=['/', print_dlm_line(l(1:ii), 'dlm', '/')];
    if ~H5L.exists(fid, p, 'H5P_DEFAULT')
        status = 0;
        break
    end
end

end
function write_annot(fid, gpname, id, desc, hd, args)

% delete link if it exists
if islinkexists(fid, gpname)
    dbg (args.verbose, '%s exists, deleting', gpname);
    H5L.delete(fid, gpname, 'H5P_DEFAULT');
end
gcpl = H5P.create ('H5P_LINK_CREATE');
H5P.set_create_intermediate_group (gcpl, 1);
% write annotation
gid = H5G.create(fid, gpname, gcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');

% Create ids if not present in the desc
write_column(gid, 'id', id, args);
for ii=1:length(hd)
    if isequal(hd{ii}, 'id')
        this_hd = 'id_renamed';
    else
        this_hd = hd{ii};
    end
    write_column(gid, this_hd, desc(:, ii), args);
end
H5G.close(gid);
end

function write_column(locid, name, d, args)
% Write a 1d-column dataset to a specified location
dims = size(d);
% write_single_ds(locid, name, d)
h5param = get_meta_datatype(d);
if h5param.numel >0
    filetype = H5T.copy (h5param.filetype);
    memtype = H5T.copy (h5param.memtype);
    % Create the dataset creation property list
    space = H5S.create_simple (1, dims(1), []);
    chunk_size = get_chunk_size(h5param.elem_per_kb, dims, args.max_chunk_kb);
    if args.compress_meta
        dcpl = set_compression('gzip', 6, chunk_size(1), false);
    else
        dcpl = H5P.create('H5P_DATASET_CREATE');
    end
    
    % set string length if char type
    if isequal(h5param.filetype, 'H5T_FORTRAN_S1')
        H5T.set_size (filetype, h5param.numel);
        H5T.set_size (memtype, h5param.numel);
    end
    % Create the dataset.
    dset = H5D.create(locid, name, memtype, space, dcpl);
    % Write the data to the dataset.
    dbg(args.verbose, 'writing %s', name);
    H5D.write(dset, filetype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', h5param.data);
    % Close and release resources.
    H5P.close(dcpl);
    H5D.close(dset);
    H5S.close(space);
else
    warning('Skipping empty field %s', name);
end
end

function p = get_matrix_datatype(matrix_class)
% get HDF5 datatype parameters
class_name = {'int32', 'int8', 'int16',...
              'int64', 'uint32', 'uint8',...
              'uint16', 'uint64',...
              'single', 'double',...
              'logical'};
% mem_type = {'H5T_NATIVE_INT', 'H5T_NATIVE_SHORT', 'H5T_NATIVE_SHORT',...
%             'H5T_NATIVE_LLONG', 'H5T_NATIVE_UINT', 'H5T_NATIVE_USHORT',...
%             'H5T_NATIVE_USHORT', 'H5T_NATIVE_ULONG',...
%             'H5T_NATIVE_FLOAT', 'H5T_NATIVE_DOUBLE'};
file_type = {'H5T_STD_I32', 'H5T_STD_I8', 'H5T_STD_I16',...
             'H5T_STD_I64', 'H5T_STD_U32', 'H5T_STD_U8',...
             'H5T_STD_U16', 'H5T_STD_U64',...
             'H5T_IEEE_F32', 'H5T_IEEE_F64',...
             'H5T_STD_U8'};
bit_size = {32, 8, 16,...
            64, 32, 8,...
            16, 64,...
            32, 64,...
            8};
endianness = 'LE';

this_class = find(strcmp(class_name, matrix_class));

if isequal(length(this_class), 1)
    p.memtype = strcat(file_type{this_class}, endianness);
    p.filetype = strcat(file_type{this_class}, endianness);
    p.elem_per_kb = 1024 * 8 / bit_size{this_class};
else
    error('Unsupported datatype: %s',...
          print_dlm_line(matrix_class, 'dlm', ','));
end
end

function p = get_meta_datatype(d)
%http://www.hdfgroup.org/HDF5/Tutor/datatypes.html#standard
nd = length(d);
c = unique(cellfun(@class, d,'uniformoutput',false));
% if multiclass cell convert to string
if length(c) > 1
    d = cellfun(@stringify, d, 'uniformoutput',false);
    iscl = strcmp('cell', cellfun(@class, d, 'uniformoutput', false));
    d(iscl) = cellfun(@(x) print_dlm_line(x, 'dlm', '|'), d(iscl),...
        'uniformoutput', false);
    c = {'char'};
end
switch c{1}
    case {'char', 'cell'}
        % convert cell to char
        if isequal(c{1}, 'cell')
            d = cellfun(@(e) print_dlm_line(e, 'dlm', '|'), d, ...
                'uniformoutput', false);
        end
        %     Note if using C strings allocate +1 byte for null termination
        %         p.memtype = 'H5T_C_S1';
        p.memtype = 'H5T_FORTRAN_S1';
        p.filetype = 'H5T_FORTRAN_S1';
        p.elem_per_kb = 1024;
        p.data = char(d)';
        p.numel = size(p.data, 1);
    case {'single', 'double'}
        p.memtype = 'H5T_IEEE_F32LE';
        p.filetype = 'H5T_IEEE_F32LE';
        p.elem_per_kb = 256;
        not_null = ~cell2mat(cellfun(@isempty, d, 'uniformoutput', false));
        if ~isequal(nd, nnz(not_null))
            p.data = nan(size(d), 'single');
            p.data(not_null) = single(cell2mat(d));
        else
            p.data = single(cell2mat(d));
        end
        
        p.numel = numel(p.data);
        
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', ...
            'uint32', 'int64', 'uint64', 'logical'}
        not_null = ~cell2mat(cellfun(@isempty, d, 'uniformoutput', false));
        if ~isequal(nd, nnz(not_null))
            % missing values, cast to float to support nans
            p.memtype = 'H5T_IEEE_F32LE';
            p.filetype = 'H5T_IEEE_F32LE';
            p.elem_per_kb = 256;
            p.data = nan(size(d), 'single');
            p.data(not_null) = single(cell2mat(d));
        else
            p.memtype = 'H5T_STD_I32LE';
            p.filetype = 'H5T_STD_I32LE';
            p.elem_per_kb = 256;
            p.data = int32(cell2mat(d));
        end
        p.numel = numel(p.data);
    otherwise
        error('Invalid datatype: %s', c{1})
end
end

function set_scalar_attr(locid, name, value)
acpl = H5P.create('H5P_ATTRIBUTE_CREATE');
aapl = 'H5P_DEFAULT';
switch class(value)
    case 'char'
        type_id = H5T.copy('H5T_FORTRAN_S1');
        H5T.set_size(type_id, length(value));
    case {'single','double'}
        type_id = H5T.copy('H5T_IEEE_F32LE');
        value = single(value);
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', ...
            'uint32', 'int64', 'uint64', 'logical'}
        type_id = H5T.copy('H5T_STD_I32LE');
        value = int32(value);
    otherwise
        error('Unsupported class for attribute: %s', class(value))
end
space_id = H5S.create('H5S_SCALAR');
attr_id = H5A.create(locid, name, type_id, space_id, acpl, aapl);
H5A.write(attr_id, 'H5ML_DEFAULT', value);
H5A.close(attr_id);
end
