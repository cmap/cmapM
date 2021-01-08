function ie = isvarexist(vname)
% ISVAREXIST Test if a variable exists.
%   IE = ISVAREXIST(VNAME)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

error(nargchk(1, 1, nargin));
ie = isequal(evalin('caller', sprintf('exist(''%s'', ''var'')',vname)), 1);
