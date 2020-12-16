function ds = parse_gctx(varargin)
%   DS = PARSE_GCTX(DSFILE) Reads a GCTX file and returns a structure
%   with the following fields:
%
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdict: Dictionary of row annotation fieldnames to indices
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdict: Dictionary of column annotation fieldnames to indices
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Path of source filename
%       h5path: Path of data matrix in the GCTX file
%       h5name: Dataset name
%
%   The default is to return the dataset stored at '/0/DATA/0/matrix'
%   within the GCTX file. To specify an alternate location specify the
%   'root' and 'dsname' options.
%
%   DS = PARSE_GCTX(DSFILE, 'param1', value1, ...) Specify optional
%   parameters:
%
%   'rid': <Cell array> specifying a subset of row identifiers to extract.
%           Default is to return all rows.
%
%   'cid': <Cell array> specifying a subset of column identifiers to
%           extract. Default is to return all columns.
%
%   'annot_only': <Boolean> Extract only row and column meta-data without
%           the data matrix. Default is false.
%   'id_only': <Boolean> Extract only row and column ids without other
%           meta-data or the data matrix. Default is false.
%
%   'skip_annot': <Boolean> Skip meta-data and return just the dta matrix
%           and the ids. Default is false.
%
%   'detect_numeric': <Boolean> Identifies numeric meta-data and casts
%           them to a an appropriate data type. Default is true
%
%   'root': Root group location in the GCTX file. Default is '0'
%
%   'dsname': Data matrix location. Default is '0'
%
%   'annot_precision': Numeric precision of numeric meta-data. Only applies
%           if detect_numeric is false. Default is 2.

% Copyright (c) 2011,2012 Broad Institute of MIT and Harvard.

[args, help_flag] = readArgs(varargin{:});

if ~help_flag
    %required fields
    reqfn = {'mat', 'rid', 'rdesc', 'rhd', 'cid', 'cdesc', 'chd'};
    
    if isstruct(args.dsfile)
        fn = fieldnames(args.dsfile);
        if isempty(setdiff(reqfn, fn))
            ds = ds_slice(args.dsfile, 'rid', args.rid, 'cid', args.cid,...
                'row_filter', args.row_filter,...
                'column_filter', args.column_filter,...
                'ignore_missing', args.ignore_missing,...
                'checkid', args.checkid);            
        else
            setdiff(reqfn, fn);
            error('Struct input does not have required fields');
        end
    elseif isfileexist(args.dsfile)
        [~,~,e] = fileparts(args.dsfile);
        switch(lower(e))
            case '.gctx'
                fid = H5F.open(args.dsfile, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                % cmap gctx version
                if args.check_version
                    gctx_version = get_gctx_version(fid);
                else
                    gctx_version = 'GCTX1.0';
                end
                
                switch (gctx_version)
                    case {'1', 'GCTX1.0'}
                        tic
                        fprintf('Reading %s ', args.dsfile);
                        dmid = sprintf('/%s/DATA/%s/matrix', args.root, args.dsname);
                        meta_row_gp = sprintf('/%s/META/ROW', args.root);
                        meta_col_gp = sprintf('/%s/META/COL', args.root);
                        req_links = {dmid, meta_row_gp, meta_col_gp};
                        isexist = is_link_exists(fid, req_links);
                        if all(isexist)
                            % mat, rid, rhd, rdesc, cid, chd, cdesc, version
                            ds = mkgctstruct;
                            ds.version =  gctx_version;
                            ds.src = args.dsfile;
                            ds.h5path = dmid;
                            if ~args.id_only
                                if args.skip_annot
                                    ds.rid = read_id(fid, meta_row_gp, args.checkid);
                                    ds.cid = read_id(fid, meta_col_gp, args.checkid);
                                else
                                    % row / col annotations
                                    [ds.rid, ds.rdesc, ds.rhd] = read_annot(fid, meta_row_gp, args);
                                    [ds.cid, ds.cdesc, ds.chd] = read_annot(fid, meta_col_gp', args);
                                    ds.rdict = list2dict(ds.rhd);
                                    ds.cdict = list2dict(ds.chd);
                                end
                                if ~args.annot_only
                                    % data matrix
                                    if ~isempty(args.rid) || ~isempty(args.cid) || ~isempty(args.row_filter) || ~isempty(args.column_filter)
                                        if ~isempty(args.rid)
                                            rid = unique(parse_grp(args.rid), 'stable');
                                            rmap = list2dict(ds.rid);
                                            ridx = dlookup(rmap, rid, args.ignore_missing);
                                            ds.rid = ds.rid(ridx);
                                            if ~isempty(ds.rdesc)
                                                ds.rdesc = ds.rdesc(ridx, :);
                                            end
                                        elseif ~isempty(args.row_filter)
                                            row_meta = gctmeta(ds, 'row');
                                            [~, keep_rec] = filter_record(row_meta, args.row_filter, 'detect_numeric', false);
                                            ridx = find(keep_rec);
                                            ds.rid = ds.rid(keep_rec);
                                            if ~isempty(ds.rdesc)
                                                ds.rdesc = ds.rdesc(keep_rec, :);
                                            end
                                        else
                                            ridx = [];
                                        end
                                        if ~isempty(args.cid)
                                            cid = unique(parse_grp(args.cid), 'stable');
                                            cmap = list2dict(ds.cid);
                                            cidx = dlookup(cmap, cid, args.ignore_missing);
                                            ds.cid = ds.cid(cidx);
                                            if ~isempty(ds.cdesc)
                                                ds.cdesc = ds.cdesc(cidx, :);
                                            end
                                        elseif ~isempty(args.column_filter)
                                            column_meta = gctmeta(ds, 'column');
                                            [~, keep_rec] = filter_record(column_meta, args.column_filter, 'detect_numeric', false);
                                            cidx = find(keep_rec);
                                            ds.cid = ds.cid(keep_rec);
                                            if ~isempty(ds.cdesc)
                                                ds.cdesc = ds.cdesc(keep_rec, :);
                                            end
                                        else
                                            cidx = [];
                                        end
                                        [ds.mat, attr] = read_matrix(fid, dmid, ridx, cidx, args.matrix_class);
                                        if isKey(attr, 'name')
                                            ds.h5name = attr('name');
                                        else
                                            ds.h5name='unnamed';
                                        end
                                        %Load a subset
                                    else
                                        %Load full matrix
                                        [ds.mat, attr] = read_matrix(fid, dmid, [], [], args.matrix_class);
                                        if isKey(attr, 'name')
                                            ds.h5name = attr('name');
                                        else
                                            ds.h5name='unnamed';
                                        end
                                    end
                                end
                            else
                                ds.rid = read_id(fid, meta_row_gp, args.checkid);
                                ds.cid = read_id(fid, meta_col_gp, args.checkid);
                            end
                        else
                            disp (req_links(~isexist));
                            error('Required links not found in H5 file');
                        end
                    otherwise
                        error('Unknown format: %s', gctx_version)
                end
                fprintf ('Done [%2.2f s].\n', toc);
                H5F.close(fid)
                
                
            case '.gct'
                ds = parse_gct(varargin{:});
            otherwise
                error('Unknown format: %s', args.dsfile)
        end
    else
        error('File %s not found', args.dsfile)
    end
end
end

function v = dlookup(dict, k, ignore_missing)
ik = dict.isKey(k);
missing = setdiff(k, dict.keys);
disp(missing);
if ~isempty(missing) && ~ignore_missing
    error('Some %d keys not found', numel(missing));
elseif ~isempty(missing)
    warning('Some %d keys not found, ignoring', numel(missing));
end
v = cell2mat(dict.values(k(ik)));

end

function matrix = read_matrix0(fid, matrix_group)
% READ_MATRIX Read data matrix from HDF5 data format.
gid = H5G.open(fid, matrix_group);
matrix = [];
[status, idx_out, matrix] = H5L.iterate(gid, 'H5_INDEX_NAME', 'H5_ITER_NATIVE', 0, @matrix_iter_func, matrix);
H5G.close(gid)
end

function [status opdata_in] = matrix_iter_func(gid, name, opdata_in)
% MATRIX_ITER_FUNC Iterator function called from READ_MATRIX.
% mappings to standard gct names
%fdict = containers.Map({'matrix','row_ids','column_ids'}, {'mat','rid','cid'});
fdict = containers.Map({'matrix'}, {'mat'});
try
    dset_id = H5D.open(gid, name);
    data = H5D.read(dset_id, 'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT');
    H5D.close(dset_id);
    switch(class(data))
        case {'single','double'}
            attr = get_obj_attr(gid, name);
            if (attr.isKey('row_major') && isequal(attr('row_major'), 0)) || (~attr.isKey('row_major'))
                opdata_in.(fdict(name)) = data;
            else
                opdata_in.(fdict(name)) = data';
            end
        case 'char'
            opdata_in.(fdict(name)) = cellstr(data');
        otherwise
            error('Error iterating %s Unknown class: %s\n', name, class(data));
    end
    status = 0;
catch
    status = -1;
end
end

function matrix = read_matrix1(fid, matrix_name, ridx, cidx)
% READ_MATRIX Read data matrix from HDF5 data format.
% Assumes ridx and cidx are sorted

matrix = [];
dset_id=H5D.open(fid, matrix_name);
%full matrix
if isempty(ridx) && isempty(cidx)
    mem_space_id = 'H5S_ALL';
    file_space_id = 'H5S_ALL';
else
    %subset
    file_space_id = H5D.get_space(dset_id);
    [rnk, dims] = H5S.get_simple_extent_dims(file_space_id);
    if ~isempty(cidx)
        ncid = length(cidx);
    else
        ncid = dims(1);
    end
    if ~isempty(ridx)
        nrid = length(ridx);
    else
        nrid = dims(2);
    end
    mem_space_id = H5S.create_simple(2, [ncid nrid],[]);
    counta = [1 dims(2)];
    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', [cidx(1)-1 0],[],counta,[]);
    for ii=2:ncid
        H5S.select_hyperslab(file_space_id, 'H5S_SELECT_OR', [cidx(ii)-1 0],[], counta, []);
    end
    if ~isempty(ridx)
        countb = [dims(1) 1];
        for ii=1:nrid
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_NOTB', [0 ridx(ii)-1], [], countb, []);
        end
        for ii=1:ncid
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_XOR', [cidx(ii)-1 0],[], counta, []);
        end
    end
end

matrix = H5D.read(dset_id, 'H5ML_DEFAULT', mem_space_id, file_space_id, 'H5P_DEFAULT');
if ~isempty(ridx)
    [~, unsrt] = sort_indices(ridx);
    matrix = matrix(unsrt, :);
end
if ~isempty(cidx)
    [~, unsrt] = sort_indices(cidx);
    matrix = matrix(:, unsrt);
end
H5D.close(dset_id);

end

function [matrix, attr] = read_matrix(fid, matrix_name, ridx, cidx, matrix_class)
% READ_MATRIX Read data matrix from HDF5 data format.
% Assumes ridx and cidx are sorted

% matrix = [];
dset_id = H5D.open(fid, matrix_name);
file_space_id = H5D.get_space(dset_id);
[~, dims] = H5S.get_simple_extent_dims(file_space_id);

%full matrix
if isempty(ridx) && isempty(cidx)
    fprintf('[%dx%d]\n',dims(2),dims(1));
    mem_space_id = 'H5S_ALL';
    file_space_id = 'H5S_ALL';
else
    %subset
    if ~isempty(cidx)
        [srt_cid, unsrt_cid] = sort_indices(cidx);
        [c_start, c_count] = compute_hs_extents(srt_cid);
        nslab_c = length(c_start);
        dimc = length(cidx);
    else
        c_start = 0;
        c_count = dims(1);
        nslab_c = 1;
        dimc = dims(1);
    end
    if ~isempty(ridx)
        [srt_rid, unsrt_rid] = sort_indices(ridx);
        [r_start, r_count] = compute_hs_extents(srt_rid);
        nslab_r = length(r_start);
        dimr = length(ridx);
    else
        r_start = 0;
        r_count = dims(2);
        nslab_r = 1;
        dimr = dims(2);
    end
    fprintf('[%dx%d]\n',dimr, dimc);
    mem_space_id = H5S.create_simple(2, [dimc dimr],[]);
    select_mode = {'col_3_pass', 'row_3_pass', 'single'};
    [nselect, opt_select] = min([(nslab_c * 2) + nslab_r,...
        (nslab_r * 2) + nslab_c,...
        nslab_c * nslab_r]);
    %     nselect = nslab_c + ~isempty(ridx)*(nslab_c + nslab_r);
    fprintf ('Performing %d hyperslab selections using %s mode\n', nselect, select_mode{opt_select});
    switch select_mode{opt_select}
        case 'single'
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', [c_start(1) r_start(1)], [], [c_count(1) r_count(1)],[]);
            [rr, cc] = meshgrid(1:nslab_r, 1:nslab_c);
            rr=rr(:);
            cc=cc(:);
            for ii=2:nselect
                H5S.select_hyperslab(file_space_id, 'H5S_SELECT_OR', [c_start(cc(ii)) r_start(rr(ii))], [], [c_count(cc(ii)) r_count(rr(ii))],[]);
            end
            
        case 'col_3_pass'
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', [c_start(1) 0], [], [c_count(1) dims(2)],[]);
            for ii=2:nslab_c
                H5S.select_hyperslab(file_space_id, 'H5S_SELECT_OR', [c_start(ii) 0], [], [c_count(ii) dims(2)], []);
            end
            if ~isempty(ridx)
                for ii=1:nslab_r
                    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_NOTB', [0 r_start(ii)], [], [dims(1) r_count(ii)], []);
                end
                for ii=1:nslab_c
                    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_XOR', [c_start(ii) 0], [], [c_count(ii) dims(2)], []);
                end
            end
            
        case 'row_3_pass'
            H5S.select_hyperslab(file_space_id, 'H5S_SELECT_SET', [0 r_start(1)], [], [dims(1) r_count(1)],[]);
            for ii=2:nslab_r
                H5S.select_hyperslab(file_space_id, 'H5S_SELECT_OR', [0 r_start(ii)], [], [dims(1) r_count(ii)], []);
            end
            if ~isempty(cidx)
                for ii=1:nslab_c
                    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_NOTB', [c_start(ii) 0], [], [c_count(ii) dims(2)], []);
                end
                for ii=1:nslab_r
                    H5S.select_hyperslab(file_space_id, 'H5S_SELECT_XOR', [0 r_start(ii)], [], [dims(1) r_count(ii)], []);
                end
            end
    end
end

matrix = H5D.read(dset_id, 'H5ML_DEFAULT', mem_space_id, file_space_id, 'H5P_DEFAULT');
if ~isempty(ridx)
    matrix = matrix(unsrt_rid, :);
end
if ~isempty(cidx)
    matrix = matrix(:, unsrt_cid);
end
if ~isempty(matrix_class) && ~isequal(class(matrix), matrix_class)
    matrix = cast(matrix, matrix_class);
end
attr = get_obj_attr(fid, matrix_name);
H5D.close(dset_id);

end

function [srt, unsrt] = sort_indices(idx)
[srt, ind] = sort(idx);
[~, unsrt] = sort(ind);
end

function [start, count] = compute_hs_extents(idx)
idx = idx(:);
c = find(diff(idx)>1);
start = [idx(1); idx(c+1)] - 1;
count = [idx(c); idx(end)] - start;
% start = idx;
% count = ones(size(start));
end

function [id, desc, hd] = read_annot(fid, annot_group, args)
% READ_ANNOT Read row and column annotations from HDF5 data format.
gid = H5G.open(fid, annot_group);
info = H5G.get_info(gid);
nlinks = info.nlinks;
id = [];
%TODO pre-allocate desc
desc = {};
hd = cell(nlinks-1, 1);
dctr = 0;
for ii=0:nlinks-1
    link_name = H5L.get_name_by_idx(fid, annot_group, 'H5_INDEX_NAME', 'H5_ITER_NATIVE', ii, 'H5P_DEFAULT');
    if strcmpi('id', link_name)
        isid = true;
    else
        isid = false;
        dctr = dctr+1;
        hd{dctr} = link_name;
    end
    dset_id = H5D.open(gid, link_name);
    data = H5D.read(dset_id, 'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT')';
    H5D.close(dset_id);
    if ischar(data)
        data = cellstr(data);
        %             if args.detect_numeric
        %                 data = detect_numeric(data);
        %             end
    else
        if isid
            % cast to string
            msgid=sprintf('%s:NonStringID', mfilename);
            fprintf(1, '\n');
            warning(msgid, 'Casting non-string id to string');
            data = strrep(cellstr(num2str(data(:))),' ', '');
        elseif args.detect_numeric
            data = num2cell(data);
        else
            data = num2cellstr(data, 'precision', args.annot_precision);
        end
    end
    if isequal(dctr, 1) && ~isid
        desc = cell(length(data), nlinks-1);
    end
    if isid
        id = data;
        check_dup_id(id, args.checkid);
    else
        desc(:, dctr) = data;
    end
end
if args.detect_numeric
    desc = detect_numeric(desc);
end
H5G.close(gid)
if isempty(id)
    H5F.close(fid)
    error('Id not specified for annotation')
end
end

function id = read_id(fid, annot_group, do_idcheck)
% READ_ID Read row and column ids from GCTX data format.

gid = H5G.open(fid, annot_group);
dset_id = H5D.open(gid, 'id');
id = H5D.read(dset_id, 'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT')';
H5D.close(dset_id);
if ischar(id)
    id = cellstr(id);
end
H5G.close(gid)
if isempty(id)
    H5F.close(fid)
    error('Id not found for %s', annot_group)
end
check_dup_id(id, do_idcheck);
end

function cleanid = strip_ids(id)
% STRIP_IDS Remove path information from row and column header names.
% CLEANID = STRIP_IDS(ID) returns a cell array of header names CLEANID
% given a cell array of raw header names.

cleanid = cell(length(id), 1);
for ii=1:length(id)
    [~, cleanid{ii}] = fileparts(id{ii});
end
end

function gctx_version = get_gctx_version(fid)
% GET_GCTX_VERSION Get CMap GCTX version info
% returns a string gctx_version containing the
% version information given a structure FILEINFO returned by hdf5info.
attr = get_obj_attr(fid, '/');
if attr.isKey('version')
    gctx_version = attr('version');
    if isnumeric(gctx_version)
        gctx_version = sprintf('%d', gctx_version);
    end
else
    gctx_version = '';
end

end




function attr = get_obj_attr(fid, obj_name)
% GET_OBJ_ATTR Get H5 object attributes.
% ATTR = GET_OBJ_ATTR(LOC_ID, OBJ_NAME)
% open object
obj_id = H5O.open(fid, obj_name, 'H5P_DEFAULT');
% get number of attributes
info = H5O.get_info(obj_id);
attr = containers.Map;
for ii=0:info.num_attrs-1
    attr_id = H5A.open_by_idx(fid, obj_name, 'H5_INDEX_NAME', ...
        'H5_ITER_NATIVE', ii, 'H5P_DEFAULT', 'H5P_DEFAULT');
    name = H5A.get_name(attr_id);
    value = H5A.read(attr_id, 'H5ML_DEFAULT');
    if ischar(value)
        value = regexprep(value(:)', '\0', '');
    end
    attr(name) = value;
end
end

function  isexist = is_link_exists(fid, links)
% IS_LINK_EXISTS Check if H5 links exist.
if ischar(links)
    links = {links};
end
n = length(links);
isexist = zeros(n, 1);
for ii=1:n
    isexist(ii) = linkcheck(fid, links{ii});
end
end

function status = linkcheck(fid, gpname)
l = tokenize(regexprep(gpname, '^/', ''), '/');
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

function [args, help_flag] = readArgs(varargin)
pnames = {'dsfile',...
    '--rid',...
    '--cid',...
    '--row_filter',...
    '--column_filter',...
    '--annot_only',...
    '--id_only',...
    '--skip_annot',...
    '--ignore_missing',...
    '--check_version',...
    '--checkid',...
    '--detect_numeric',...
    '--matrix_class',...
    '--dsname',...
    '--annot_precision',...
    '--root',...
    '--verbose'};
dflts = {'',...
    '',...
    '',...
    '',...
    '',...
    false,...
    false,...
    false,...
    false,...
    true,...
    true,...
    true,...
    '',...
    '0',...
    2,...
    '0',...
    false};
help_str = {'GCT(x) file or data structure',...
    'Cell array or GRP file specifying a subset of row identifiers to extract',...
    'Cell array or GRP file specifying a subset of column identifiers to extract',...
    'GMT or GMX file or structure specifying rules to filter rows on. See parse_filter for details on specifying the rules',...
    'GMT or GMX file or structure specifying rules to filter columns on. See parse_filter for details on specifying the rules',...
    'Boolean, If true returns only row and column meta-data without the data matrix',...
    'Boolean, If true returns only row and column ids without other meta-data or the data matrix',...
    'Boolean if true ignores meta-data and returns just the data matrix and the ids',...
    'Boolean, If true ignores missing row or column ids specified via the --rid and --cid arguments. The default behaviour is to generate an error.',...
    'Boolean, if true validates the GCTX version string',...
    'Boolean, if true validates if row and column ids are unique',...
    'Boolean, If true identifies numeric meta-data and casts them to the appropriate data type',...
    'String representing a valid numeric class, If not empty casts the matrix data to specified class',...
    'String, Data matrix location in the HDF5 hierarchy',...
    'Integer, Precision of numeric meta-data. Only applies if detect_numeric is false',...
    'String, Root group location in the HDF5 file',...
    'Boolean, If true prints verbose messages',...
    };
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename,...
    'desc', 'Read a GCT(x) file and returns a data structure.',...
    'undef_action', 'warn');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
end
