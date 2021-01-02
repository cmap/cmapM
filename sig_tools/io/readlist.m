%READLIST read a list from a text file
% l = readlist(fname)
% hashes (#) are treated as comments and ignored

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function l = readlist(fname)

if exist(fname)

    l = textread(fname,'%s','commentstyle','shell','whitespace','\n');

end
