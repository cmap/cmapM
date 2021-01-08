classdef Generic
    methods (Static=true)
        % Collate a list of datasets to disk
        outFile = collateDatasets(fileList,...
                                 outFile,...
                                 varargin);   
        % get list of files matching criteria
        fileList = getFileList(varargin);
    end
end