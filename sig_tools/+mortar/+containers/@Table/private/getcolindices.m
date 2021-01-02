function [colIndices,newNames] = getcolindices(a,colIndices,allowNew)
%GETCOLINDICES Process string, logical, or numeric dataset array column indices.

%   Copyright 2006-2012 The MathWorks, Inc.


if nargin < 3, allowNew = false; end
newNames = {};

% Translate variable (column) names into indices
if ischar(colIndices)
    if strcmp(colIndices, ':') % already checked ischar
        % have to translate these, since dataset column indexing is not done
        % by the built-in indexing code
        colIndices = 1:a.ncols;
    elseif size(colIndices,1) == 1
        varName = colIndices;
        colIndices = find(strcmp(varName,a.varnames));
        if isempty(colIndices)
            if allowNew
                checkreservednames(varName);
                colIndices = a.ncols+1;
                newNames = {varName};
            else
                error('mortar:containers:table:getcolindices:UnrecognizedColName', varName);
            end
        end
    else
        error('mortar:containers:table:getcolindices', 'InvalidVarName');
    end
elseif iscellstr(colIndices)
    varNames = colIndices;
    colIndices = zeros(1,numel(colIndices));
    maxIndex = a.ncols;
    for j = 1:numel(colIndices)
        varIndex = find(strcmp(varNames{j},a.varnames));
        if isempty(varIndex)
            if allowNew
                checkreservednames(varNames{j});
                maxIndex = maxIndex+1;
                varIndex = maxIndex;
                newNames{1,varIndex-a.ncols} = varNames{j};
            else
                error('mortar:containers:table:getcolindices:UnrecognizedVarName', varNames{ j });
            end
        end
        colIndices(j) = varIndex;
    end
elseif isnumeric(colIndices) || islogical(colIndices)
    if islogical(colIndices)
        % have to translate these, since dataset column indexing is not done by
        % the built-in indexing code
        colIndices = find(colIndices);
        if isempty(colIndices)
            maxIndex = [];
        else
            maxIndex = colIndices(end);
        end
    else
        maxIndex = max(colIndices);
    end
    if maxIndex > a.ncols
        if allowNew
            if any(diff(unique([1:a.ncols colIndices(:)'])) > 1)
                error('mortar:containers:table:getcolindices', 'DiscontiguousVars');
            end
            % create default names for the new vars, but make sure they don't
            % conflict with existing names.
            newNames = dfltvarnames((a.ncols+1):maxIndex);
            varnames = internal.matlab.codetools.genuniquenames([a.varnames newNames],a.ncols+1);
            newNames = varnames(a.ncols+1:end);
        else
            error('mortar:containers:table:getcolindices', 'VarIndexOutOfRange');
        end
    end
    % already have col numbers, leave them alone
else
    error('mortar:containers:table:getcolindices', 'InvalidVarSubscript');
end
colIndices = colIndices(:)';
