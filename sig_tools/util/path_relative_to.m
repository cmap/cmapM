function relPath = path_relative_to(fromPath, toPath)
% PATH_RELATIVE_TO Find the relative path from one folder to another file
%                  or folder.
%   RP = PATH_RELATIVE_TO(FP, TP) returns the relative path to TP from FP.
%   FP is a string, TP can be string or a cell array of strings. Both FP
%   and TP are absolute paths.
%
%   fp='/foo/bar';
%   tp={'test.txt', '/xyz/abc/test2.txt', '/', '/foo/bar/test2.txt'}
%   rp = path_relative_to(fp, tp)

% Note: only tested on unix

narginchk(2, 2);
assert(ischar(fromPath))
assert(ischar(toPath) | iscell(toPath));

if isempty(fromPath)
    fromPath='.';
end

if ~isequal(fromPath(end), filesep)
    fromPath = [fromPath, filesep];
end
fp = fileparts(fromPath);

if ischar(toPath)
    ischarinput = true;
    toPath = {toPath};
else
    ischarinput = false;
end
np = length(toPath);

relPath = cell(np, 1);
fdir = tokenize(fp, filesep);
nfdir = length(fdir);
relsep = {'..'};
for ii=1:np
    [tp, tf, te] = fileparts(toPath{ii});    
    tdir = tokenize(tp, filesep);
    ntdir = length(tdir);
    ndir = min(nfdir, ntdir);    
    % find common root
    root_idx = find([~strcmp(fdir(1:ndir), tdir(1:ndir)); true],...
                    1, 'first') - 1;
                
if root_idx>0
    rp = print_dlm_line([relsep(ones(nfdir-root_idx, 1));...
                        tdir(root_idx+1:ntdir)], 'dlm', '/');
    relPath{ii} = fullfile(rp, [tf, te]);
else
    relPath{ii} = toPath{ii};
end

if ischarinput
    % return a string if input was a string
    relPath = relPath{1};
end

end
