function initgctx(dsfile, rid, cid, fill_value, varargin)
% Initialize a gctx file with a specified fill value.

pnames = {'root', 'dsname', 'name',...
    'compression', 'compression_level'...
    'max_chunk_kb', 'overwrite', 'version',...
    'rid', 'cid', 'insert',...
    'appenddim','update', 'verbose',...
    'chunk_size'};
dflts = {'0','0','unnamed',...
    'none', 6,...
    1024, false, 'GCTX1.0',...
    '', '', false,...
    true, false, false,...
    []};
args = parse_args(pnames, dflts, varargin{:});

tic
nr = length(rid);
nc = length(cid);

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
rdesc = '';
rhd = '';
cdesc = '';
chd = '';
write_annot(file, sprintf('/%s/META/ROW', args.root), rid, rdesc, rhd, args)
write_annot(file, sprintf('/%s/META/COL/', args.root), cid, cdesc, chd, args)

%create data group
write_scalar(file, args.root, args.dsname, nr, nc, fill_value, args)
H5F.close(file);

fprintf ('done [%2.2fs].\n', toc);
end


function write_scalar(fid, root, mid, nr, nc, fill_value, args)
% write data matrix
dims = [nr, nc];
% % 1Mb chunks
% max_chunk_kb = 1024;
% compression_type = 'gzip';
% compression_level = 6;

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

if isempty(args.chunk_size)
    % Auto chunk size
    switch(dtype)
        case 'char'
            elem_per_kb = 1024;
        otherwise
            %  256 = 1024 / 4 bytes per float
            elem_per_kb = 256;
    end
    chunk_size = [dims(1), min(max(floor((max_chunk_kb * elem_per_kb) / dims(1)), 10), dims(2))];
else
    assert(all(isnumeric_type(args.chunk_size)) && ...
        isequal(length(args.chunk_size), 2), ...
        'Invalid chunk size specified');
    chunk_size = args.chunk_size;
end

dcpl = set_compression('float', dims, args.compression, ...
    args.compression_level, chunk_size);

% set fill value
type_id = H5T.copy('H5T_NATIVE_DOUBLE');
H5P.set_fill_value(dcpl, type_id, fill_value);

% Create the dataset.
dset = H5D.create(gid, 'matrix', 'H5T_IEEE_F32LE', space, dcpl);

set_scalar_attr(dset, 'row_major', int32(0))
set_scalar_attr(dset, 'name', args.name);

% Close and release resources.
H5P.close(dcpl);
H5D.close(dset);
H5S.close(space);

H5G.close(gid);
end

function dcpl = set_compression(dtype, dims, compression, compression_level, chunk_size, verbose)
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

dbg(verbose, 'Setting chunk size to: %dx%d',...
    chunk_size(1), chunk_size(2));
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
