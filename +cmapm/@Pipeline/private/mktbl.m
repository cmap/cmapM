function mktbl(outfile, tbl, varargin)
% MKTBL Create a delimted text table.
%   MKTBL(OUTFILE, TBL) Creates tab delimited text file OUTFILE. TBL can be
%   a structure or a cell array. Two types of structures are supported. TBL
%   can be single structure where each fieldname comprised a cell array of
%   length equal to the number of rows in the table. Alternatively TBL can
%   be a a 1D structure array of length equal to the number of rows in the
%   table and each element having the same fieldnames. TBL can also be a 2D
%   cell array. 
%
%   MKTBL(OUTFILE, TBL, param1, value1,...). Specify optional parameters:
%   'precision': scalar integer, precision of numeric values. Default is
%       INF where the precision is selected automatically.
%   'dlm': string, delimiter. Default is '\t'
%   'emptyval': string, Substitution for empty values. Default is ''
%   'header': cell array, Alternate fieldnames, length must equal number of
%       fields in the table. If TBL is a cell array, the fieldnames are
%       auto generated if header is not specified.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
% TODO
% optimize write speed
% c = {'a','foo','hello world'};
% nrow = length(c);
% mask = char(0);
% dlm = char(9);
% newline = char(13);
% blank = char(32);
% [char(c), newline(ones(nrow, 1))]


pnames = {'precision', 'dlm', 'emptyval',...
        'header', 'noheader', 'verbose',...
        'keep_field'};
dflts = {inf, '\t', '',...
        '', false, true,...
        ''};
args = parse_args(pnames, dflts, varargin{:});

if ~isempty(tbl)
switch class(tbl)
    case 'struct'
        nr = length(tbl);
        if ~isempty(args.header)
            if isequal(length(args.header), length(fieldnames(tbl)))
                fn = args.header;
                fnidx = 1:length(fn);
            else
                error('Header length does not match number of columns');
            end
        else
            if ~isempty(args.keep_field)
                [fn, fnidx] = intersect_ord(fieldnames(tbl), args.keep_field);
            else
                fn = fieldnames(tbl);
                fnidx = 1:length(fn);
            end
        end
        nf = length(fn);
       
        if isequal (nr, 1) && check_field_length(tbl, fn)
            % Legacy mode, single structure where each fieldname is an array of
            % size nrec
            nrec = length((tbl.(fn{1})));
            x = struct2cell(tbl);
            x = x(fnidx);
            % convert to columns
            x = cellfun(@(x)(x(:)), x, 'uniformoutput', false);
            isnum = cellfun(@(x) isnumeric(x)||islogical(x), x);
            if any(isnum)
                idx = find(isnum);
                n = nnz(isnum);
                for ii=1:n
                    x{idx(ii)} =  num2cellstr(x{idx(ii)}, 'precision', args.precision);
                end
            end
            data = [x{:}];
        else
            % preferred form, structure array of size nrec
            nrec = nr;
            data = struct2cell(tbl(:))';
        end
    case 'cell'
        [nrec, nf] = size(tbl);
        data = tbl;
        if ~isempty(args.header)
            if isequal(length(args.header), nf)
                fn = args.header;
            else
                error('Header length does not match number of columns');
            end
        else
            fn = gen_labels(nf, 'prefix', 'COL_');
        end
    otherwise
        error ('Unsupported TBL format: %s', class(tbl))
end

dbg (args.verbose, 'Saving file to %s [%dr x %dc]', outfile, nrec, nf);
% write without automatic flushing
fid = fopen(outfile, 'wb');
% print header
if ~args.noheader
    print_dlm_line(fn, 'fid', fid, 'dlm', args.dlm);
end

for ii=1:nrec
    print_dlm_line(data(ii,1:nf), 'fid', fid, ...
        'dlm', args.dlm, 'precision', args.precision, ...
        'emptyval', args.emptyval);
end

fclose(fid);
else
    dbg(1,'Empty table supplied, skipping');
end
end

function tf = is_legacy_struct(tbl)
tf = all(struct2array(structfun(@(x) isequal(class(x), 'cell'),...
         tbl, 'uniformoutput', false)));
end

function same_len = check_field_length(tbl, fn)
nf = length(fn);
len = length(tbl.(fn{1}));
same_len = true;
for ii=2:nf
    if ~isequal(len, length(tbl.(fn{ii})))
        same_len = false;
        break;
    end    
end

end

