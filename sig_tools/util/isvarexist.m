function ie = isvarexist(vname)
% ISVAREXIST Test if a variable exists.
%   IE = ISVAREXIST(VNAME)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

narginchk(1, 1);
ie = isequal(evalin('caller', sprintf('exist(''%s'', ''var'')',vname)), 1);
