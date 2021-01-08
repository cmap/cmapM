function mkgctx(dsfile, ds, varargin)
% MKGCT_H5 Save a GCT dataset in HDF5 format.
% MKGCT_H5(DSFILE, DS)
% Note: assumes data matrix is at single precision

pnames = {'root', 'dsname', 'name',...
    'compression', 'compression_level'...
    'max_chunk_kb', 'overwrite', 'version',...
    'rid', 'cid', 'insert',...
    'appenddim','update', 'verbose'};
dflts = {'0','0','unnamed',...
    'none', 6,...
    1024, false, 'GCTX1.0',...
    '', '', false,...
    true, false, false};
args = parse_args(pnames, dflts, varargin{:});

tic
error(nargchk(2, 15, nargin))
if args.insert || args.update
    
    fprintf ('Appending dataset to: %s...\n', dsfile);
    insert_ds(dsfile, ds, args)   
else    
    if ~isempty(args.rid)
        args.rid = parse_grp(args.rid);
    end
    if ~isempty(args.cid)
        args.cid = parse_grp(args.cid);
    end
    
    ds = reorder_ds(ds, args.rid, args.cid);
    [nr,nc] = size(ds.mat);
    if args.appenddim
        [p, f] = fileparts(dsfile);
        %strip old dimension if it exists
        prefix = rm_filedim(f);
        dsfile = fullfile(p, sprintf('%s_n%dx%d.gctx', prefix, nc, nr));
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
% reorder rows to match
ds = gctextract_tool(ds, 'rid', annot.rid);
% new samples
[ncid, ncidx] = setdiff(ds.cid, annot.cid);
% existing samples
[ecid, ecidx_ds, ecidx_annot] = intersect(ds.cid, annot.cid);

if ~isempty(ecid) || ~isempty(ncid)
    
    fid = H5F.open(dsfile, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    
    %UPDATES
    if ~isempty(ecid)
        if args.update
            update_matrix(fid, args.root, args.dsname,...
                ds.mat(:, ecidx_ds), ecidx_annot, args);
        else
            %disp(ecid);
            dbg(args.verbose, 'Ignoring %d/%d samples that already exist in dsfile', ...
                length(ecid), length(ds.cid))
        end
    end
    
    %INSERTS
    if ~isempty(ncid)
        insert_matrix(fid, args.root, args.dsname, ds.mat(:, ncidx), args);
    end
    
    % Column annotations
    newcid = [annot.cid; ncid];
    if isequal(annot.chd, ds.chd) && ~args.update
        % annotations in same order, simply append
        newchd = annot.chd;
        newcdesc = [annot.cdesc; ds.cdesc(ncidx,:)];
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
            newcdesc(length(annot.cid)+(1:length(ncidx)), chidx_new2) = ...
                ds.cdesc(ncidx, chidx_ds);
            % update existing annotations
            if args.update
                newcdesc(ecidx_annot, chidx_new2) = ds.cdesc(ecidx_ds, chidx_ds);
            end
        end
    end
    if length(ncid)>0 || args.update
        write_annot(fid, sprintf('/%s/META/COL', args.root), newcid, newcdesc, newchd, args)
    end
    H5F.close(fid);
end

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

function update_matrix(fid, root, mid, mat, cidx, args)
%update samples in existing data matrix

dims = size(mat);
gpname = sprintf('/%s/DATA/%s', root, mid);
gid = H5G.open(fid, gpname); 
dset_id = H5D.open(gid, 'matrix', 'H5P_DEFAULT');
file_space_id = H5D.get_space(dset_id);
% Current dimensions
[~, h5_dims, ~] = H5S.get_simple_extent_dims(file_space_id);
% matlab_dims: rows x cols
matlab_dims = fliplr(h5_dims);

%row extents should match
if ~isequal(dims(1), matlab_dims(1))
    error('Row size mismatch (is %d expected %d)', dims(1), matlab_dims(1))
end
nc = length(cidx);
file_space_id = H5D.get_space(dset_id);
col_dims = [matlab_dims(1), 1];
mem_space_id = H5S.create_simple(2, fliplr(col_dims), []);

dbg(args.verbose, 'Updating %d columns', dims(2));

for ii=1:nc
    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', ...
    [cidx(ii)-1 0], [], [1 matlab_dims(1)], []);
    H5D.write(dset_id, 'H5T_NATIVE_FLOAT', mem_space_id, file_space_id,...
        'H5P_DEFAULT', single(mat(:,ii)))
end

H5D.close(dset_id);

end

function insert_matrix(fid, root, mid, mat, args)
% Insert samples into existing data matrix
dims = size(mat);
gpname = sprintf('/%s/DATA/%s', root, mid);
gid = H5G.open(fid, gpname); 
dset_id = H5D.open(gid, 'matrix', 'H5P_DEFAULT');
file_space_id = H5D.get_space(dset_id);
% Current dimensions
[~, h5_dims, ~] = H5S.get_simple_extent_dims(file_space_id);
% fprintf('ndims:%d, h5_dims:%dx%d, max_dims: %dx%d\n', ndims, ...
%     h5_dims(1), h5_dims(2), h5_maxdims(1), h5_maxdims(2));
% matlab_dims: rows x cols
matlab_dims = fliplr(h5_dims);

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
H5D.write(dset_id, 'H5T_NATIVE_FLOAT', ...
    mem_space_id, file_space_id, 'H5P_DEFAULT', ...
    single(mat));

H5D.close(dset_id);

end

function write_matrix(fid, root, mid, mat, args)
% write data matrix
dims = size(mat);
% % 1Mb chunks
% max_chunk_kb = 1024;
% compression_type = 'gzip';
% compression_level = 6;

h5filters = containers.Map({'gzip', 'szip'}, {'H5Z_FILTER_DEFLATE', 'H5Z_FILTER_SZIP'});
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

dcpl = set_compression('float', dims, args.compression, ...
    args.compression_level, args.max_chunk_kb);

% Create the dataset.
dset = H5D.create(gid, 'matrix', 'H5T_IEEE_F32LE', space, dcpl);

% Write the data to the dataset.
H5D.write(dset, 'H5T_NATIVE_FLOAT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', single(mat));
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

function dcpl = set_compression(dtype, dims, compression, compression_level, max_chunk_kb, verbose)
% Create the dataset creation property list, add the gzip
% compression filter and set the chunk size.  Remember to flip
% the chunksize.
if ~isdefined('verbose')
    verbose=1;
end
dcpl = H5P.create('H5P_DATASET_CREATE');

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

% Set chunk size
switch(dtype)
    case 'char'
        elem_per_kb = 1024;
    otherwise
        %  256 = 1024 / 4 bytes per float
        elem_per_kb = 256;
end
chunk = [dims(1) min(floor( (max_chunk_kb * elem_per_kb) / dims(1)), dims(2))];
dbg(verbose, 'Using max chunk: %dK, setting chunk size to: %dx%d',...
    max_chunk_kb, chunk(1), chunk(2));
H5P.set_chunk (dcpl, fliplr(chunk));

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
    write_column(gid, hd{ii}, desc(:, ii), args);
end
H5G.close(gid);
end

function write_column(locid, name, d, args)
% Write a 1d-column dataset to a specified location
dims = size(d);
% write_single_ds(locid, name, d)
h5param = get_h5_param(d);
if h5param.numel >0
filetype = H5T.copy (h5param.filetype);
memtype = H5T.copy (h5param.memtype);
% Create the dataset creation property list
dcpl = H5P.create('H5P_DATASET_CREATE');
space = H5S.create_simple (1, dims(1), []);
% Create dataspace.  Setting maximum size to [] sets the maximum
% size to be the current size.  Remember to flip the dimensions.
% maxdims = fliplr([dims(1), H5ML.get_constant_value('H5S_UNLIMITED')]);
% space = H5S.create_simple (2, fliplr(dims), maxdims);
% % dcpl = set_compression(args.compression, args.compression_level)
% dcpl = set_compression('char', dims, args.compression, ...
%     args.compression_level, args.max_chunk_kb, 0);

% set string length if char type
if isequal(h5param.filetype, 'H5T_FORTRAN_S1')
    H5T.set_size (filetype, h5param.numel);
    H5T.set_size (memtype, h5param.numel);
end
% Create the dataset.
dset = H5D.create(locid, name, memtype, space, dcpl);
% Write the data to the dataset.
H5D.write(dset, filetype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', h5param.data);
dbg(args.verbose, 'writing %s', name);
% Close and release resources.
H5P.close(dcpl);
H5D.close(dset);
H5S.close(space);
else
    warning('Skipping empty field %s', name);
end
end

function p = get_h5_param(d)
%http://www.hdfgroup.org/HDF5/Tutor/datatypes.html#standard
c = unique(cellfun(@class, d,'uniformoutput',false));
% if multiclass cell convert to string
if length(c) > 1
    d = cellfun(@stringify, d, 'uniformoutput',false);
    c = {'char'};
end
switch c{1}
    case 'char'
%     Note if using C strings allocate +1 byte for null termination
        %         p.memtype = 'H5T_C_S1';
        p.memtype = 'H5T_FORTRAN_S1';
        p.filetype = 'H5T_FORTRAN_S1';
        p.data = char(d)';
        p.numel = size(p.data, 1);
    case {'single','double','logical'}
        p.memtype = 'H5T_IEEE_F32LE';
        p.filetype = 'H5T_NATIVE_FLOAT';
        not_null = ~cell2mat(cellfun(@isempty, d, 'uniformoutput', false));
        p.data = -666*ones(size(d), 'single');
        p.data(not_null) = single(cell2mat(d));
        p.numel = numel(p.data);
    otherwise
        disp(class(d))
        error('Invalid datatype')
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
        type_id = H5T.copy('H5T_NATIVE_FLOAT');        
        value = single(value);
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', ...
            'uint32', 'int64', 'uint64', 'logical'}
        type_id = H5T.copy('H5T_NATIVE_INT');        
        value = int32(value);        
    otherwise
        error('Unsupported class for attribute: %s', class(value))
end
space_id = H5S.create('H5S_SCALAR');
attr_id = H5A.create(locid, name, type_id, space_id, acpl, aapl);
H5A.write(attr_id, 'H5ML_DEFAULT', value);
H5A.close(attr_id);
end
