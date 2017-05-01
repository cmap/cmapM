function varargout = gctextract_tool(infile, varargin)
% GCTEXTRACT_TOOL Extract a subset of data from a GCT file.
%   GCTEXTRACT_TOOL(FILENAME, 'param1', value1, ...) 
%   Extracts a subset of data from FILENAME. The following parameters are
%   supported:
%       Parameter   Value
%       'rid'       List of row ids to extract, specified as a GRP file.
%                   Default is all row ids.
%       'cid'       List of column ids to extract, specified as a GRP file.
%                   Default is all column ids.
%       'rdesc'     Row descriptors, specified as a TBL file. Default is to
%                   keep descriptors from the source file.
%       'cdesc'     Column descriptors to include in the extracted dataset.
%                   Specified as a TBL file. Default is to keep
%                   descriptors from the source file.
%       'key_rdesc' Key field in rdesc that matches the row id of the
%                   source file. Default is 'id'
%       'key_cdesc' Key field in cdesc that matches the column id of the
%                   source file. Default is 'id'
%       'out'       Ouput folder. Default is PWD.
%       'mkdir'     Create a subfolder for the output file. Default is
%                   true.
%       'transpose' Transpose the data matrix. Default is false.
%       'xform'     Transform the data matrix. Default is 'none'.
%                   Valid options are:
%                   {'abs', 'log2', 'pow2', 'exp', 'log', 'zscore', 'none'}

toolName = mfilename;
valid_xform = {'zscore','log2','abs','pow2','exp','log','none'};
pnames = {'cdesc', 'rdesc', ...
    'rid', 'cid', 'out', ...
    'xform','precision','key_cdesc',...
    'key_rdesc','transpose','mkdir'};
dflts =  {'', '',...
    '', '', pwd, ...
    'none', 4, 'id',...
    'id', 0, true};

isnout = nargout>0;
args = parse_args(pnames, dflts, varargin{:});
if ~isnout
    print_args(toolName, 1, args);
end

if ischar(infile) || isstruct(infile)
      ds = parse_gct(infile);
else
    error ('devtools:gctextract_tool:InvalidInput', 'Infile is not valid')
end

% rowid space
if (iscell(args.rid) || isfileexist(args.rid))
    rspace = parse_grp(args.rid);    
    if ~isempty('rspace')
        [cmn_rid, ridx] = intersect_ord(ds.rid, rspace);
        if ~isequal(length(rspace), length(ridx))
            warning('Some row ids were not found!')
            disp(setdiff(rspace, cmn_rid))
        end
        % subset gct to use
        ds.mat = ds.mat(ridx, :);
        ds.rid = cmn_rid;
        if ~isempty(ds.rdesc)
            ds.rdesc = ds.rdesc(ridx, :);
        end
    end
end
%columnid space
if (iscell(args.cid) || isfileexist(args.cid))
    cspace = parse_grp(args.cid);
    if ~isempty('cspace')
        [cmn_cid, cidx] = intersect_ord(ds.cid, cspace);
        if ~isequal(length(cspace), length(cidx))
            warning('Some column ids were not found!')
            disp(setdiff(cspace, cmn_cid))
        end
        %subset of gct to use
        ds.mat = ds.mat(:, cidx);
        ds.cid = cmn_cid;
        if ~isempty(ds.cdesc)
            ds.cdesc = ds.cdesc(cidx, :);
        end
    end
end
if isfileexist(args.cdesc)
    ds = annotate_ds(ds, args.cdesc, 'dim', 'column', 'keyfield', args.key_cdesc);
end

if isfileexist(args.rdesc)
    ds = annotate_ds(ds, args.rdesc, 'dim', 'row', 'keyfield', args.key_rdesc);
end
%transform if required
ds.mat = do_xform(ds.mat, args.xform, 'valid_xform', valid_xform, 'verbose', ~isnout);

if args.transpose
    ds = transpose_gct(ds);
end
%% analysis ouput folders
if ~isnout
    if args.mkdir
        wkdir = mkworkfolder(args.out, toolName);
    else
        wkdir = args.out;
    end
    fprintf ('Saving analysis to %s\n',wkdir);

    % save parameters
    print_args(toolName, sprintf('%s_params.txt',toolName), args);

    if isfield(ds, 'src')
        infile = ds.src;
    else
        infile = 'ds.gct';
    end
    [~,f,e] = fileparts(infile);
    mkgct(fullfile(wkdir,[f,e]), ds, 'precision', args.precision);    
else
    varargout(1) = {ds};
end


