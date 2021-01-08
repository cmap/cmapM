function [outFile, status] = httpget(URI, outPath, overwrite, encode_str)
% HTTPGET download o file from a web URL.
% HTTPGET(URI, OUTFILE) Downloads the file specified by URI and saves
% it to OUTFile

narginchk(2,4);
nin = nargin;
if (nin < 3) 
    overwrite = false;
    encode_str = false;
end

if (nin < 4)
    encode_str = false;
end

assert(ischar(URI), 'URI should be a string');
assert(ischar(outPath), 'Outfile should be a string');
assert(islogical(overwrite), 'overwrite should be logical');

if encode_str
    URI = mortar.util.File.encodeURL(URI);
end

if mortar.common.FileUtil.isfile(outPath, 'dir')
    % save the object using terminal part of key
    [~, fileName, fileExt]=fileparts(URI);
    outPath = fullfile(outPath, [fileName, fileExt]);
end

if (~mortar.common.FileUtil.isfile(outPath) || overwrite)
    [outFile, status] = urlwrite(URI, outPath);
else
    dbg(1, 'File: %s exists, not overwriting', outPath);
    outFile = outPath;
    status = 1;
end


end