function [outFile, status] = urlget(URI, outPath, overwrite, encode_str)
% URLGET download an HTTP or Amazon S3 object. 
%   URLGET(URI, OUTPATH) Downloads the object specified by URI and saves
%   it to OUTPATH. If OUTPATH is a folder, the object is saved to the
%   folder using the URI name, otherwise the object is saved to a file
%   specified by OUTPATH.
%
% Example: 
%   urlget('s3://data.lincscloud.org/index.html','index.html')
%   urlget('http://data.lincscloud.org.s3.amazonaws.com/index.html','index.html')
%   urlget('s3://data.lincscloud.org/index.html','outfolder')

if ~isvarexist('overwrite')
    overwrite = false;
end
if ~isvarexist('encode_str')
    encode_str = false;
end

ut = uri_type(URI);

switch (ut)
    case 'http'
        [outFile, status] = httpget(URI, outPath, overwrite, encode_str);    
    case 's3'
        [outFile, status] = s3get(URI, outPath, overwrite);
    case 'file'
        if ~isequal(URI, outPath)
            if isdirexist(outPath)
                [~, f, e] = fileparts(URI);
                outFile = fullfile(outPath, [f, e]);
            else
                outFile = outPath;
            end
            if ~isfileexist(outFile) || overwrite
                status = copyfile(URI, outFile);
            end
        end
end


end
