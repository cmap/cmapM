% PARSE_LXB Parse a Luminex LXB (binary or text) file
%   LXB = PARSE_LXB(LXBFILE) Returns a sructure (LXB) with fieldnames set 
%   to header labels in row one of LXBFILE.
%
% See also parse_lbxbin, parse_lxbtxt

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function sins = parse_lxb(lxbfile, varargin)

if isfileexist(lxbfile)
    [p,f,e] = fileparts(lxbfile);
    switch lower(e)
    %binary
        case '.lxb'
            sins = parse_lxbbin(lxbfile, varargin{:});
    %text file
        case '.txt'
            sins = parse_lxbtxt(lxbfile);
    end
else
    error ('File: %s not found!\n', lxbfile);
end

