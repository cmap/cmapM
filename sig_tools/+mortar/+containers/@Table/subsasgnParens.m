function a = subsasgnParens(a,s,b,creating)
% '()' is assignment to a subset of a dataset array.  Only dot subscripting
% may follow.

%   Copyright 2012-2013 The MathWorks, Inc.


if numel(s(1).subs) ~= a.ndims
    error(message('mortar:containers:Table:subsasgn:NDSubscript'));
end

if ~isscalar(s)
    switch s(2).type
    case '()'
        error('mortar:containers:Table:subsasgn', 'InvalidSubscriptExpr');
    case '{}'
        error('mortar:containers:Table:subsasgn', 'InvalidSubscriptExpr');
    case '.'
        if creating
            error('mortar:containers:Table:subsasgn', 'InvalidSubscriptExpr');
        end
        
        % Syntax:  a(obsIndices,varIndices).name = b
        %
        % Assignment into a variable of a subarray.
        
        % Get the subarray, do the dot-variable assignment on that
        % *** need to accept out of range obs or var indices/names here
        % *** as assignment to grow the dataset
        c = subsrefParens(a,s(1));
        b = subsasgnDot(c,s(2:end),b);
        
        % Now let the simple () subscripting code handle assignment of the updated
        % subarray back into the original array.
        s = s(1);
    end
end


% If a new dataset is being created, or if the LHS is 0x0, then interpret
% ':' as the size of the corresponding dim from the RHS, not as nothing.
if exist('_isEmptySqrBrktLiteral', 'builtin')>0
    deleting = builtin('_isEmptySqrBrktLiteral',b);
else
    deleting = isempty(b);
end
colonFromRHS = ~deleting && (creating || all(size(a)==0));

% Translate row names into indices (leave ':' alone)
if colonFromRHS && iscolon(s(1).subs{1})
    rowIndices = 1:b.nrows;
    numRowIndices = b.nrows;
    maxRowIndex = b.nrows;
    newRowNames = {};
else
    [rowIndices,numRowIndices,maxRowIndex,newRowNames] = ...
                               getrowindices(a, s(1).subs{1}, ~deleting);
end

% Translate column names into indices (translate ':' to 1:ncols)
if colonFromRHS && iscolon(s(1).subs{2})
    colIndices = 1:b.ncols;
    newColNames = b.columns;
else
    [colIndices,newColNames] = getcolindices(a, s(1).subs{2}, ~deleting);
end

% Syntax:  a(obsIndices,:) = []
%          a(:,varIndices) = []
%          a(obsIndices,varIndices) = [] is illegal
%
% Deletion of complete observations or entire variables.
if deleting
    % Delete observations across all variables
    if iscolon(s(1).subs{2})
        if isnumeric(rowIndices)
            rowIndices = unique(rowIndices);
            numRowIndices = numel(rowIndices);
        end
        newNrows = a.nrows - numRowIndices;
        a_data = a.data_;
        for j = 1:a.ncols
            col_j = a_data{j};
            if ismatrix(col_j)
                col_j(rowIndices,:) = []; % without using reshape, may not be one
            else
                sizeOut = size(col_j); 
                sizeOut(1) = newNrows;
                col_j(rowIndices,:) = [];
                col_j = reshape(col_j, sizeOut);
            end
            a_data{j} = col_j;
        end
        a.data_ = a_data;
        if ~isempty(a.rows), a.rows(rowIndices) = []; end
        a.nrows = newNrows;

        % Delete entire variables
    elseif iscolon(s(1).subs{1})
        colIndices = unique(colIndices); % getvarindices converts all varindex types to numeric
        a.data_(colIndices) = [];
        a.columns(colIndices) = [];
        a.ncols = a.ncols - numel(colIndices);
        % Var-based properties need to be shrunk.
        if ~isempty(a.props.VarDescription), a.props.VarDescription(colIndices) = []; end
        if ~isempty(a.props.Units), a.props.Units(colIndices) = []; end

    else
        error('mortar:containers:Table:subsasgn', 'InvalidEmptyAssignment');
    end

% Syntax:  a(obsIndices,varIndices) = b
%
% Assignment from a dataset.  This operation is supposed to replace or
% grow at the level of the _dataset_.  So no internal reshaping of
% variables is allowed -- we strictly enforce sizes. In other words, the
% existing dataset has a specific size/shape for each variable, and
% assignment at this level must respect that.
elseif isa(b, class(a))
    if isscalar(b) % scalar expansion of a single dataset element, which may itself be non-scalar
        b = scalarRepmat(b,numRowIndices,length(colIndices));
    else
        if b.nrows ~= numRowIndices
            error('mortar:containers:Table:subsasgn', 'RowDimensionMismatch');
        end
        if b.ncols ~= length(colIndices)
            error('mortar:containers:Table:subsasgn', 'ColDimensionMismatch');
        end
    end

    existingColLocs = find(colIndices <= a.ncols);
    a_data = a.data_; 
    b_data = b.data_;
    for j = existingColLocs
        col_j = a_data(:, colIndices(j));
        % The size of the RHS has to match what it's going into.
        sizeLHS = size(col_j);
        if ~isequal(sizeLHS, size(b_data))
            error('mortar:containers:Table:subsasgn:DimensionMismatch', a.columns{colIndices(j)});
        end
        if iscolon(rowIndices)
            col_j = b_data(:, j);
        else
            try %#ok<ALIGN>
                col_j(rowIndices, :) = b_data{j}(:,:);
            catch ME, throw(ME); end
        end
        % No need to check for size change, RHS and LHS are identical sizes.
        a_data(:, colIndices(j)) = col_j;
    end
    a.data_ = a_data;

    % Add new variables if necessary.  Note that b's varnames do not
    % propagate to a in () assignment, unless a is being created or grown
    % from 0x0.  They do for horzcat, though.
    newColLocs = find(colIndices > a.ncols);
    if ~isempty(newColLocs)
        internal.matlab.codetools.genvalidnames(newColNames,false); % error if any invalid

        a_data = [a_data cell(1,length(newColNames))];
        a_nrows = a.nrows;
        for j = 1:length(newColNames)
            col_b = b_data{newColLocs(j)};
            if iscolon(rowIndices)
                col_j = col_b;
            else
                % Start the new variable out as 0-by-(trailing size of b),
                % then let the assignment add rows.
                col_j = repmat(col_b,[0 ones(1,ndims(col_b)-1)]);
                col_j(rowIndices,:) = col_b(:,:);
            end
            % A new var may need to grow to fit the dataset
            if size(col_j,1) < a_nrows
                warning('mortar:containers:Table:subsasgn:DefaultValuesAddedVariable', newColNames{j});
                col_j = lengthenVar(col_j, a_nrows);
            end
            a_data{a.ncols+j} = col_j;
        end
        a.data_ = a_data;
        LHSCols = 1:a.ncols;
        RHSCols = 1:b.ncols;
        a.columns = [a.columns newColNames];
        a.ncols = a.ncols + length(newColNames);
        % column-based properties need to be extended.
        a.props.VarDescription = catVarProps(a.props.VarDescription,b.props.VarDescription,LHSCols,RHSCols);
        a.props.Units = catVarProps(a.props.Units,b.props.Units,LHSCols,RHSCols);
    end

    if (maxRowIndex > a.nrows)
        % Don't warn if a had no columns originally
        if a.ncols > b.ncols
            warning('mortar:containers:Table:subsasgn:DefaultValuesAdded', 'DefaultValuesAdded');
        end
        % Note that b's row names do not propogate to a with ()
        % assignment.  They do for vertcat, though.
        a = fillInDataset(a,maxRowIndex,newRowNames);
    end

else
    % Raw values are not accepted as the RHS with '()' subscripting:  With a
    % single variable, you can use dot subscripting.  With multiple variables,
    % you can either wrap them up in a dataset, accepted above, or use braces
    % if the variables are homogeneous.
%     error('mortar:containers:Table:subsasgn', 'InvalidRHS');
    error('mortar:containers:Table:subsasgn:InvalidRHS', 'InvalidRHS');
end
