function [fn, fp] = find_file(p)
% FIND_FILE Search for files.
% [FN, FP] = FIND_FILE(P) Searches for files in the specified path P. 

if isvarexist('p')
    if isdirexist(p)
        folder = p;
    else
        folder = fileparts(p);
    end
    d = dir(p);
    fn = {d.name}';
    % fullpath
    if ~isempty(d)
        fp = cellfun(@(x) fullfile(folder, x), fn, 'uniformoutput', false);
    else
        fp = {};
    end
%     if isequal(length(fn), 1)
%         fp = fp{1};
%         fn = fn{1};
%     end
else
    error('Path not specified')
end

end