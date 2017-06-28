function ds = parse_gctx(dsfile, varargin)
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


% Author: Rajiv Narayan <narayan at broadinstitute dot org>
% Copyright (c) 2011,2012 Broad Institute of MIT and Harvard.

pnames = {'detect_numeric', 'annot_precision', 'root',...
    'dsname', 'rid', 'cid',...
    'annot_only'};
dflts = {true, 2, '0',...
    '0', {}, {},...
    false};
args = parse_args(pnames, dflts, varargin{:});

%required fields
reqfn = {'mat', 'rid', 'rdesc', 'rhd', 'cid', 'cdesc', 'chd'};

if isstruct(dsfile)
    fn = fieldnames(dsfile);
    if isempty(setdiff(reqfn, fn))
        ds = dsfile;
        clear('dsfile');
    else
        setdiff(reqfn, fn);
        error('Struct input does not have required fields');
    end
elseif isfileexist(dsfile)
    [~,~,e] = fileparts(dsfile);
    switch(lower(e))
        case '.gctx'
            fid = H5F.open(dsfile, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            % cmap h5 version
            h5version = get_h5_version(fid);
            switch (h5version)
                case {'1', 'GCTX1.0'}
                    tic
                    fprintf('Reading %s ', dsfile);
                    dmid = sprintf('/%s/DATA/%s/matrix', args.root, args.dsname);
                    meta_row_gp = sprintf('/%s/META/ROW', args.root);
                    meta_col_gp = sprintf('/%s/META/COL', args.root);
                    req_links = {dmid, meta_row_gp, meta_col_gp};
                    isexist = is_link_exists(fid, req_links);
                    if all(isexist)
                        % mat, rid, rhd, rdesc, cid, chd, cdesc, version
                        ds = mkgctstruct;
                        ds.version =  h5version;
                        ds.src = dsfile;
                        ds.h5path = dmid;
                        % row / col annotations
                        [ds.rid, ds.rdesc, ds.rhd] = read_annot(fid, meta_row_gp, args);
                        [ds.cid, ds.cdesc, ds.chd] = read_annot(fid, meta_col_gp', args);
                        ds.rdict = list2dict(ds.rhd);
                        ds.cdict = list2dict(ds.chd);
                        if ~args.annot_only
                            % data matrix
                            if ~isempty(args.rid) || ~isempty(args.cid)
                                %Load a subset
                                if ~isempty(args.rid)
                                    rid = parse_grp(args.rid);
                                    rmap = list2dict(ds.rid);
                                    ridx = dlookup(rmap, rid);
                                    ds.rid = ds.rid(ridx);
                                    if ~isempty(ds.rdesc)
                                        ds.rdesc = ds.rdesc(ridx, :);
                                    end
                                else
                                    ridx = [];
                                end
                                if ~isempty(args.cid)
                                    cid = parse_grp(args.cid);
                                    cmap = list2dict(ds.cid);
                                    cidx = dlookup(cmap, cid);
                                    ds.cid = ds.cid(cidx);
                                    if ~isempty(ds.cdesc)
                                        ds.cdesc = ds.cdesc(cidx, :);
                                    end
                                else
                                    cidx = [];
                                end
                                [ds.mat, attr] = read_matrix(fid, dmid, ridx, cidx);
                                if isKey(attr, 'name')
                                    ds.h5name = attr('name');                                    
                                else
                                    ds.h5name='unnamed';
                                end                                
                            else
                                %Load full matrix
                                [ds.mat, attr] = read_matrix(fid, dmid, [], []);
                                if isKey(attr, 'name')
                                    ds.h5name = attr('name');
                                else
                                    ds.h5name='unnamed';
                                end
                            end
                        end
                    else
                        disp (req_links(~isexist));
                        error('Required links not found in H5 file');
                    end
                otherwise
                    error('Unknown format: %s', h5version)
            end
            fprintf ('Done [%2.2f s].\n', toc);
            H5F.close(fid)
        case '.gct'
            ds = parse_gct(dsfile, varargin{:});
        otherwise
            error('Unknown format: %s', dsfile)
    end
else
    error('File %s not found', dsfile)
end
end

function v = dlookup(dict, k)
if all(dict.isKey(k))
    v = cell2mat(dict.values(k));
else
    setdiff(k, dict.keys)
    error('Some keys not found');
end
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

function [matrix, attr] = read_matrix(fid, matrix_name, ridx, cidx)
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
    nselect = nslab_c + ~isempty(ridx)*(nslab_c + nslab_r);
    fprintf ('Performing %d hyperslab selections\n', nselect);
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
end

matrix = H5D.read(dset_id, 'H5ML_DEFAULT', mem_space_id, file_space_id, 'H5P_DEFAULT');
if ~isempty(ridx)
    matrix = matrix(unsrt_rid, :);
end
if ~isempty(cidx)
    matrix = matrix(:, unsrt_cid);
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
        else
            if args.detect_numeric
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

function cleanid = strip_ids(id)
% STRIP_IDS Remove path information from row and column header names.
% CLEANID = STRIP_IDS(ID) returns a cell array of header names CLEANID
% given a cell array of raw header names.

cleanid = cell(length(id), 1);
for ii=1:length(id)
    [~, cleanid{ii}] = fileparts(id{ii});    
end
end

function h5version = get_h5_version(fid)
% GET_H5_VERSION Get C-Map H5 version info
% H5VER = GET_H5_VERSION(FILEINFO) returns a string H5VER containing the
% version information given a structure FILEINFO returned by hdf5info.
attr = get_obj_attr(fid, '/');
if attr.isKey('version')
    h5version = attr('version');
    if isnumeric(h5version)
        h5version = sprintf('%d', h5version);
    end
else
    h5version = '';
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
