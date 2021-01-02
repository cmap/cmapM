function varargout = get_filedim(s)
% Get dimensions from filename
%  [NR, NC] = GET_FILEDIM(S)
%   file_n123 -> 123
%   file_n1x10 -> [10, 1]

tok = regexp(s,'_n([0-9]*)x([0-9]*)|_n([0-9]*)','tokens');
if ~isempty(tok)
    dim = str2double(tok{1});
    if length(dim)>1
        dim = {dim(2); dim(1)};
    else
        dim = {dim(1); []};
    end
    
    varargout = dim;
    
else
    varargout = cell(nargout, 1);
end

end