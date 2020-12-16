function build = parse_build(build_path)
% Given a path, function returns a struct to represent the build within
% MATLAB. Builds contain Level 3 through 5 matrices as well as meta data in
% the form of instinfo (level 3,4) and siginfo (level 5) files.
% 
% Author: Anup Jonchhe
% Date Created: September 23, 2019

    file_list = dir(build_path);
    assert(~isempty(file_list), '%s empty, check path', build_path);

    files = file_list(~[file_list.isdir], :);
    build = struct('build_dir', build_path, 'level3', [], 'level4', [], 'level5',[], 'siginfo', [], 'instinfo', []);

    idx = rematch({files.name}, '^.*level3_.*.gctx?$', 'ignorecase');
    build.level3 = struct('name', {files(idx).name}, 'path',fullfile(build_path, {files(idx).name}));

    idx = rematch({files.name}, '^.*level4_.*.gctx?$', 'ignorecase');
    build.level4 = struct('name', {files(idx).name}, 'path',fullfile(build_path, {files(idx).name}));

    idx = rematch({files.name}, '^.*level5_.*.gctx?$', 'ignorecase');
    build.level5 = struct('name', {files(idx).name}, 'path',fullfile(build_path, {files(idx).name}));

    idx = rematch({files.name}, '^siginfo.txt$') | rematch({files.name}, '^.*sig_metrics.*.txt$');
    build.siginfo = struct('name', {files(idx).name}, 'path',fullfile(build_path, {files(idx).name}));

    idx = rematch({files.name}, '^.*inst_?info.txt$');
    build.instinfo = struct('name', {files(idx).name}, 'path',fullfile(build_path, {files(idx).name}));

end
