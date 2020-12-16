function out = paste(c, dlm)
% PASTE join columns of a cell array
% S = PASTE(C, DLM) Joins columns of C delimited by string DLM. Returns a
% cell array with the same number of rows as in C.

[nr, nc] = size(c);

% Cast numeric columns to strings
for ii=1:nc
    if mortar.util.DataType.isCellNumeric(c(:, ii))
        c(:, ii) = num2cellstr(cell2mat(c(:, ii)));
    end
end

% sprintf expects a transposed cell array
s = c';
fmt={'%s'};
this_fmt = fmt(ones(1, nc));
outfmt = sprintf(['%s', dlm], this_fmt{:});
out = sprintf([outfmt(1:end-length(dlm)), '\n'], s{:});
% return cell array
out = string_split(out(1:end-1), '\n');

end
