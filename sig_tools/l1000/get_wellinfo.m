function [wells, varargout] = get_wellinfo(wn, varargin)
% GET_WELLINFO Parse plate well ids and coordinates
%
% WN = GET_WELLINFO(WL) Parse well identifiers from WL a cell array of
% strings and returns the well names WN in a standard zero-padded format.
%
% [WN, WORD] = GET_WELLINFO(WL) Returns the well position in a 
% 384-well plate in column major order. WORD is a positive integer ranging
% [1, 384]
%
% [WN, IR, IC] = GET_WELLINFO(WL) Returns the well row and column position
% in a 384 well plate
%
% [WN, IR, IC] = GET_WELLINFO(WL, param1, value1, ...) Specify optional
% arguments
%   'plateformat' : char, Plate layout. Choices are {'384', '96'}. Default
%                   is '384'
%   'zeropad' : logical, Turns of zero-padding the well ids if false.
%               Default is true
%   'dim' : char, ordering to use when reporting well position. Choices are
%           {'column', 'row'}. Default is 'column'


pnames = {'plateformat', 'zeropad', 'dim'};
dflts = {'384', true, 'column'};

nout = nargout;
nargoutchk(1, 3);

arg = parse_args(pnames, dflts, varargin{:});
dim_str = get_dim2d(arg.dim);

switch arg.plateformat
    case {'384', 384}
        platemap = fullfile(mortarpath,'resources','384_plate.txt');
        nr = 16;
        nc = 24;
    case {'96', 96}
        platemap = fullfile(mortarpath,'resources','96_plate.txt');
        nr = 8;
        nc = 12;
    otherwise
        error('Unsupported plate size: %s', arg.plateformat)
end

if ~isempty(wn)
    if ischar(wn)
        wn = {wn};
    else
        wn = wn(:);
    end
    
    fmt = {'lxb', 'csv', 'pipe'};
    nfmt = length(fmt);
    
    % 386 well fmt
    if isfileexist(platemap)
        wellfmt = parse_tbl(platemap, 'verbose', false);
        if isequal(dim_str, 'column')
            colord = wellfmt.colmajor_order;
        else
            colord = wellfmt.rowmajor_order;
        end
        
        % try all formats
        for ii=1:nfmt
            wells = parse_wells(wn, fmt{ii});
            [cmn, idx] = map_ord(wellfmt.well, wells);
            if isequal(cmn, wells) && ~isempty(idx)
                if arg.zeropad
                    wells = wellfmt.wellzero(idx);
                end
                wellord = colord(idx);
                break
            else
                [cmn2, idx2] = map_ord(wellfmt.wellzero, wells);
                if isequal(cmn2, wells) && ~isempty(idx2)
                    wellord = colord(idx2);
                    break
                else
                    fprintf('Warning: the wells loaded from platemap do not match the well from parsing filenames.  platemap:  %s  examples of filenames wn{1}:  %s  wn{2}:  %s  wn{3}:  %s \n', ...
                        platemap, wn{1}, wn{2}, wn{3});
                end
            end
        end
    else
        error('Plate map not found: %s', platemap);
    end
else
    wells = {};
    wellord = [];
end
if nout>2
    if isequal(dim_str, 'column')
        [ir, ic] = ind2sub([nr, nc], wellord);
    else
        [ic, ir] = ind2sub([nc, nr], wellord);
    end
    varargout{1} = ir;
    varargout{2} = ic;
else
    varargout{1} = wellord;
end

end

function wells = parse_wells(wn, fmt)
wells = {};
switch lower(fmt)
    case 'lxb'
        wells = regexprep(upper(wn), '^.*_|\.LXB|\.TXT','');
    case 'csv'
        [mat, tok] = regexp(wn,'.*,(\w+))','match','tokens');
        if ~isempty(tok{1})
            wells = cellfun(@(v){v{1}{1}}, tok);
        end
        % pipeline format det_plate:det_well
    case 'pipe'
        [mat,tok]=regexp(wn, '.*:(\w+)', 'match','tokens');
        if ~isempty(tok{1})
            wells = cellfun(@(v)v{1}(1), tok);
        end
end
end
