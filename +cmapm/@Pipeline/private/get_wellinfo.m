function [wells, wellord] = get_wellinfo(wn, varargin)

pnames = {'plateformat', 'zeropad'};
dflts = {'384', true};

arg = parse_args(pnames, dflts, varargin{:});

switch arg.plateformat
    case {'384', 384}
        platemap = fullfile('resources','384_plate.txt');
        nr = 16;
        nc = 24;
    case {'96', 96}
        platemap = fullfile('resources','96_plate.txt');
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
        colord = wellfmt.colmajor_order;
        
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