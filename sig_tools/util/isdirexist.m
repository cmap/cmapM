function ie = isdirexist(fname)
% ISDIREXIST Test if a directory exists.
%   IE = ISDIREXIST(FNAME)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

narginchk(1,1);
ie = isequal(exist(fname, 'dir'),7);
