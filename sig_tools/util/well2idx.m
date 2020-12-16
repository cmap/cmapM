function wellidx = well2idx(wn, varargin)
% WELL2IDX Convert well location to numeric position
%   IDX = WELL2IDX(W) returns the well position in column major order
%   corresponding to wells W specified as a cell array of strings. 
%
%   IDX = WELL2IDX(W, 'platefmt', P) specify alternate plate layouts.
%   Supported choices are '384' and '96'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:47 EDT

pnames = {'platefmt'};
dflts = {'384'};
arg = parse_args(pnames, dflts, varargin{:});
if ischar(wn)
    wn = {wn};
end

switch arg.platefmt
    case {'384','96'}
        % 384 well fmt        
        wellfmt = parse_sin(fullfile(mortarpath,'resources',sprintf('%s_plate.txt',arg.platefmt)), false);
        colord = str2double(wellfmt.COLMAJOR_ORDER);        
        [cmn, idx] = intersect_ord(wellfmt.WELL, wn);
        if ~isequal(cmn, wn)
            disp(setdiff(wn, cmn));
            error('Well info could not be extracted for some wells');
        else
            wellidx = colord(idx);
        end
    otherwise
        error('Unknown platefmt: %s', arg.platefmt);
end


