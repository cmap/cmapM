function [rowIndices,numIndices,maxIndex,newNames] = getrowindices(a,rowIndices,allowNew)
%GETROWINDICES Process string, logical, or numeric dataset array row indices.

%   Copyright 2006-2012 The MathWorks, Inc.


if nargin < 3, allowNew = false; end
newNames = {};

% Translate observation (row) names into indices
if ischar(rowIndices)
    if strcmp(rowIndices, ':') % already checked ischar
        % leave them alone
        numIndices = a.nrows;
        maxIndex = a.nrows;
    elseif size(rowIndices,1) == 1
        obsName = rowIndices;
        rowIndices = find(strcmp(obsName,a.obsnames));
        if isempty(rowIndices)
            if allowNew
                rowIndices = a.nrows+1;
                newNames = {obsName};
            else
                error('mortar:containers:table:getrowindices:UnrecognizedObsName', obsName);
            end
        end
        numIndices = 1;
        maxIndex = rowIndices;
    else
        error('mortar:containers:table:getrowindices', 'InvalidObsName');
    end
elseif iscellstr(rowIndices)
    obsNames = rowIndices;
    rowIndices = zeros(1,numel(rowIndices));
    maxIndex = a.nrows;
    for i = 1:numel(rowIndices)
        obsIndex = find(strcmp(obsNames{i},a.obsnames));
        if isempty(obsIndex)
            if allowNew
                maxIndex = maxIndex+1;
                obsIndex = maxIndex;
                newNames{obsIndex-a.nrows,1} = obsNames{i};
            else
                error('mortar:containers:table:getrowindices:UnrecognizedObsName', obsNames{ i });
            end
        end
        rowIndices(i) = obsIndex;
    end
    numIndices = numel(rowIndices);
    maxIndex = max(rowIndices);
elseif isnumeric(rowIndices) || islogical(rowIndices)
    % leave the indices themselves alone
    if isnumeric(rowIndices)
        numIndices = numel(rowIndices);
        maxIndex = max(rowIndices);
    else
        numIndices = sum(rowIndices);
        maxIndex = find(rowIndices,1,'last');
    end
    if maxIndex > a.nrows
        if allowNew
            if ~isempty(a.obsnames)
                % If the target dataset has obsnames, create default names for
                % the new observations, but make sure they don't conflict with
                % existing names.
                newNames = dfltobsnames((a.nrows+1):maxIndex);
                obsnames = internal.matlab.codetools.genuniquenames([a.obsnames; newNames],a.nrows+1);
                newNames = obsnames(a.nrows+1:end);
            end
        else
            error('mortar:containers:table:getrowindices', 'ObsIndexOutOfRange');
        end
    end
else
    error('mortar:containers:table:getrowindices', 'InvalidObsSubscript');
end
rowIndices = rowIndices(:);
