function ofile = mkgct(ofile, gex, varargin)
% MKGCT.M Create a gct file.
%   MKGCT(OFILE, GEX) Creates OFILE in gct format. GEX is a structure with
%   the following fields:
%   Creates a v1.3 GCT file named OFILE. GEX is a structure with the 
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename
%
%   MKGCT(OFILE, GEX, 'param', value, ...) accepts one or more
%   comma-separated parameter name/value pairs. The following parameters
%   are recognized:
%
%   'precision': scalar, restricts number of digits after the decimal point
%               to N digits. Default: 4
%   'appenddim': boolean, append dimensions of the data matrix
%               to the filename. Default=true
%   'version': scalar, Support versions 2,3. Default=3. If v3 is selected
%               GEX must contain the SDESC field.
%
% See also PARSE_GCT
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Nov.22.2010 12:01:46 EDT

% Changes:
% 11.22.2010: Version 3 support
% TODO: version 2 support broken

error(nargchk(2, 10, nargin));

pnames = {'precision', 'appenddim', 'version', ...
    'parsetags', 'annot_precision', 'data'};
dflts = {4, true, 3,...
    true, inf, 'mat'};
args = parse_args(pnames, dflts, varargin{:});

[nr,nc] = size(gex.(args.data));

if args.appenddim
    [p, f, e] = fileparts(ofile);
    %strip old dimension if it exists
    prefix = regexprep(f, '_n[0-9]*x[0-9]*$','');
    ofile = fullfile(p, sprintf('%s_n%dx%d.gct', prefix, nc, nr));
end

fprintf('Saving file to %s\n', ofile')
fprintf ('Dimensions of matrix: [%dx%d]\n', nr, nc)

args.precision = round(args.precision);
fprintf ('Setting precision to %d\n', args.precision);
fmt = sprintf('%%.%df\t', args.precision);

fid = fopen(ofile,'wt');

if isequal(args.version, 3)
    nrdesc = length(gex.rhd);
    ncdesc = length(gex.chd);
    colkeys = gex.chd;
    
%     [nrdesc, gex.gd]= get_annot(gex.gd, args.parsetags);
%     % sample desc is optional
%     if any(strcmp('sdesc', fieldnames(gex)))
%        [ncdesc, gex.sdesc] = get_annot(gex.sdesc, args.parsetags);
%        colkeys = gex.sdesc.keys;
%     else
%         ncdesc = 0;
%     end    
    fprintf(fid,'#1.%d\n%d\t%d\t%d\t%d\n', args.version, nr, nc, nrdesc, ncdesc);
    % line 3: sample row desc keys and sample names
    print_dlm_line(['id'; gex.rhd; gex.cid(:)], 'fid', fid);    
    % line4 + ncdesc: sample desc keys and sample descriptor(s)    
    filler = {'na'};
    for ii=1:ncdesc
        print_dlm_line([colkeys{ii}; filler(ones(nrdesc, 1)); ...
            gex.cdesc(:, ii)], ...
            'fid', fid, 'precision', args.annot_precision);
    end
    
else
    fprintf(fid,'#1.%d\n%d\t%d\n', args.version, nr, nc);
    print_dlm_line(['id'; 'Description'; gex.sid(:)], fid);    
end

for ii=1:nr
    s = sprintf (fmt, gex.(args.data)(ii,:));
    % row name
    fprintf (fid, '%s\t', gex.rid{ii});
    for jj=1:nrdesc
        % row desc
        fprintf (fid, '%s\t', stringify(gex.rdesc{ii, jj}));
    end
    fprintf (fid, '%s\n', s(1:end-1));    
end
fclose(fid);
fprintf ('Saved.\n')
end

% standardize annotation fields
function [n, annot] = get_annot(annot, parsetags)
switch(class(annot))
    case 'cell'
        if ~parsetags || any(cellfun(@isempty, strfind(annot, '=')))
            n = 1;
            annot = containers.Map({'desc'}, {annot});
        elseif parsetags 
            annot = tags2dict(annot);
            n = length(annot);
        end
    case 'containers.Map'
        n = length(annot);
    otherwise
        error('Unknown descriptor class: %s', class(annot))
end
end