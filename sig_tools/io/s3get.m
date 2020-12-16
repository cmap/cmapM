function [outFile, status] = s3get(s3URI, outPath, overwrite)
% S3GET download an Amazon S3 object. 
%   S3GET(S3URI, OUTPATH) Downloads the object specified by S3URI and saves
%   it to OUTPATH. If OUTPATH is a folder, the object is saved to the
%   folder using the URI name, otherwise the object is saved to a file
%   specified by OUTPATH.
%
% Example: 
%   s3get('s3://data.lincscloud.org/index.html','index.html')
%   s3get('s3://data.lincscloud.org/index.html','outfolder')

if ~isvarexist('overwrite')
    overwrite = false;
end

[outFile, status] = mortar.containers.S3.get(s3URI, outPath, overwrite);

end

