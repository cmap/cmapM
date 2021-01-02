function a = subsasgnBraces(a,s,b)
% '{}' is assignment to or into the contents of a subset of a dataset array.
% Any sort of subscripting may follow.

%   Copyright 2012-2013 The MathWorks, Inc.


% '{}' is assignment of raw values into a dataset element.  Could be any
% sort of subscript following that.  The shape of the element differs,
% depending on the dimensionality of the var: if the var is nxp, the
% element is 1xp, while if the var is nxpxqx..., the element is pxqx... .
% This is much like time series behavior.  Also, if the var is a column of
% cells, then the element is technically a scalar cell, but it seems
% sensible to do one extra "contents of", and not force callers to say
% a{i,j}{1}.
if numel(s(1).subs) ~= a.ndims
    error('mortar:containers:table:NDSubscript', 'NDSubscript');
end

% Translate observation (row) names into indices (leaves ':' alone)
% [rowIndex,numRowIndices,~,newRowNames] = getrowindices(a, s(1).subs{1}, true);
rowIndex = a.ix_(s(1).subs{1}, 1);

% Translate variable (column) names into indices (translates ':').  Do not
% allow variable creation with {}-indexing.
% colIndex = getcolindices(a, s(1).subs{2}, false);
colIndex = a.ix_(s(1).subs{2}, 2);
if isscalar(b)
    % a{ir, ic} = b
    a.data_(rowIndex, colIndex) = {b};
else
    % a{ir, ic} = m
    if isequal(size(b), size(a.data_(rowIndex, colIndex)))
        if iscell(b)
            % a{i, j} = cell array
          a.data_(rowIndex, colIndex) = b;
        elseif isa(b, class(a))
            % a{i, j} = table(:, j)
            % note that row and column names are ignored
          a.data_(rowIndex, colIndex) = b.data_;
        else
            % a{i, j} = numeric array
            a.data_(rowIndex, colIndex) = num2cell(b);
        end
    else
        error('mortar:containers:table:SizeMismatch', 'Size mismatch');
    end
    
end
% if numRowIndices > 1 || ~isscalar(colIndex)
%     error('mortar:containers:table:MultipleElementAssignment', 'MultipleElementAssignment');
% end
% 
% % Extract an existing column
% col_j = a.data_{colIndex};
% 
% % Syntax:  a{obsIndex,varIndex} = b
% %
% % Assignment to an element of a dataset.
% if isscalar(s)
%     if exist('_isEmptySqrBrktLiteral', 'builtin')>0
%         isEmptySqBrkt = builtin('_isEmptySqrBrktLiteral',b);
%     else
%         isEmptySqBrkt = isempty(b);
%     end
%     if isEmptySqBrkt && ~iscell(col_j)
%         error(message('mortar:containers:table:InvalidEmptyAssignmentToElement'));
%     elseif iscell(col_j)
%         if numel(col_j) == size(col_j,1)
%             % If the element is a scalar cell, assign into its contents.
%             col_j{rowIndex,:} = b;
%         else
%             error(message('mortar:containers:table:MultipleCellAssignment'));
%         end
%     else
%         % Set up a subscript expression that will assign to the entire
%         % element  the specified observation/variable.  Size checks
%         % will be handled by a{i,j}'s subsasgn.
%         subs{1} = rowIndex; subs{2:ndims(col_j)} = ':';
%         try %#ok<ALIGN>
%             col_j(subs{:}) = b;
%         catch ME, throw(ME); end
%         % *** this error may not even be possible ***
%         if size(col_j,1) ~= a.nrows
%             error('mortar:containers:table:InvalidColumnReshape', 'InvalidColumnReshape');
%         end
%     end
% 
% % Syntax:  a{obsIndex,varIndex}(...) = b
% %          a{obsIndex,varIndex}{...} = b
% %          a{obsIndex,varIndex}.name = b
% %
% % Assignment into an element of a dataset.  This operation is allowed
% % to change the shape of the variable, as long as the number of rows
% % does not change.
% else % ~isscalar(s)
%     if iscell(col_j)
%         if numel(col_j) == size(col_j,1)
%             % If the element is a scalar cell, assign into its contents
%             s(1).subs = {rowIndex}; % s(1).type is already '{}'
%         else
%             error(message('mortar:containers:table:MultipleCellAssignment'));
%         end
% 
%     else
%         % Transfer the observation index from the dataset-level
%         % subscript expression to the beginning of the existing
%         % element subscript expression, and do the assignment at
%         % the element level.
%         s(2).subs = [rowIndex s(2).subs];
%         s = s(2:end);
%     end
% 
%     % Let a{i,j}'s subsasgn handle the cascaded subscript expressions.
% 
%     % *** subsasgn allows certain operations that the interpreter
%     % *** would not, for example, changing the shape of var_j by
%     % *** assignment.
%     if isscalar(s) % ~iscell(var_j) && length(s_original)==2
%         if isobject(col_j)
%             if isobject(b) && ~isa(b,class(col_j))
%                 try %#ok<ALIGN>
%                     col_j = col_j.subsasgn(s,b); % dispatch to var_j's subsasgn
%                 catch ME, throw(ME); end
%             else
%                 try %#ok<ALIGN>
%                     col_j = subsasgn(col_j,s,b);
%                 catch ME, throw(ME); end
%             end
%         else
%             % Call builtin, to get correct dispatching even if b is an object.
%             try %#ok<ALIGN>
%                 col_j = builtin('subsasgn',col_j,s,b);
%             catch ME, throw(ME); end
%         end
%     else % ~iscell(var_j) && length(s_original)>2, or iscell(var_j) && length(s_original)>1
%         % *** A hack to get the third and higher levels of subscripting in
%         % *** things like ds{i,'Var'}(...) etc. to dispatch to the right place
%         % *** when ds{i,'Var'}, or something further down the chain, is itself
%         % *** a dataset.
%         try %#ok<ALIGN>
%             col_j = statslibSubsasgnRecurser(col_j,s,b);
%         catch ME, rethrow(ME); end % point to the line in statslibSubsasgnRecurser
%     end
% 
%     % Do not allow growing a variable with brace assignment into a variable
%     if size(col_j,1) ~= a.nrows
%         error(message('mortar:containers:table:InvalidVarReshape'));
%     end
% end
% 
% % If the var is shorter than the dataset, fill it out.  This should never
% % happen; assigning into a var cannot shorten the number of rows.
% colLen = size(col_j,1);
% if colLen < a.nrows
%     warning(message('mortar:containers:table:DefaultValuesAddedVariable', a.columns{colIndex}));
%     col_j = lengthenVar(col_j, a.nrows);
% 
% % If a var was lengthened by assignment, fill out the rest of the dataset,
% % including observation names.
% elseif colLen > a.nrows
%     warning(message('mortar:containers:table:DefaultValuesAdded'));
%     a = fillInDataset(a, colLen, newRowNames);
% end
% 
% a.data_{colIndex} = col_j;
